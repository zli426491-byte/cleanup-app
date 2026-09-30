#!/usr/bin/env bash
set -euo pipefail

# Prepare Flutter's generated configuration and Pods without building a second
# app whose reinstall could invalidate the simulator's Photos permission.
mkdir -p build/native-tests
RUN_DIRECTORY="$(mktemp -d build/native-tests/run.XXXXXX)"
DERIVED_DATA="$PWD/build/native-test-derived-data"
flutter build ios --simulator --debug --no-codesign --config-only \
  --target integration_test/photo_library_scan_test.dart \
  --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false \
  2>&1 | tee "$RUN_DIRECTORY/flutter-config.log"

SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in reversed(list(data["devices"].items())):
    if ".iOS-" not in runtime:
        continue
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
raise SystemExit("No available iPhone simulator")
')"
SIMULATOR_STATE="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
device_id = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["udid"] == device_id:
            print(device["state"])
            sys.exit(0)
raise SystemExit("Selected simulator is missing")
' "$SIMULATOR_ID")"
if [[ "$SIMULATOR_STATE" != "Booted" ]]; then
  xcrun simctl boot "$SIMULATOR_ID"
fi
XCODE_ARGUMENTS=(
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -derivedDataPath "$DERIVED_DATA" \
  -parallel-testing-enabled NO \
  "ARCHS=$(uname -m)" \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=
)
# An exact source/toolchain cache hit may reuse compiled products. Never use a
# partial restore or skip the native tests themselves.
PRODUCTS="$DERIVED_DATA/Build/Products"
CACHED_TEST_RUNS=("$PRODUCTS"/*.xctestrun)
if [[ "${NATIVE_TEST_PRODUCTS_CACHE_HIT:-false}" == "true" ]] && \
   [[ -f "$PRODUCTS/.cleanup-build-succeeded" ]] && \
   [[ -d "$PRODUCTS/Debug-iphonesimulator/Runner.app/PlugIns/RunnerTests.xctest" ]] && \
   [[ -d "$PRODUCTS/Debug-iphonesimulator/RunnerUITests-Runner.app/PlugIns/RunnerUITests.xctest" ]] && \
   [[ "${#CACHED_TEST_RUNS[@]}" == "1" ]] && [[ -f "${CACHED_TEST_RUNS[0]}" ]]; then
  echo "Reusing native test products from an exact source/toolchain cache hit."
else
  xcodebuild build-for-testing "${XCODE_ARGUMENTS[@]}" \
    2>&1 | tee "$RUN_DIRECTORY/xcodebuild-build.log"
  touch "$PRODUCTS/.cleanup-build-succeeded"
fi
python3 - "$SIMULATOR_ID" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'bootstatus', sys.argv[1], '-b'],
               check=True, timeout=180)
PY
TEST_APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Runner.app"
UI_TEST_APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/RunnerUITests-Runner.app"
test -d "$TEST_APP"
test -d "$UI_TEST_APP/PlugIns/RunnerUITests.xctest"
# Verify ad-hoc identity before installing. Simulator signatures use no account
# credentials and do not change the release IPA's signing configuration.
codesign --verify --strict "$TEST_APP"
codesign -dvvv "$TEST_APP" 2>&1 | tee "$RUN_DIRECTORY/host-signature.txt"
codesign -dr - "$TEST_APP" 2>&1 | tee "$RUN_DIRECTORY/host-requirement.txt"
codesign -dvvv "$TEST_APP/PlugIns/RunnerTests.xctest" \
  2>&1 | tee "$RUN_DIRECTORY/test-signature.txt"
codesign --verify --strict "$UI_TEST_APP"
codesign -dvvv "$UI_TEST_APP" 2>&1 | tee "$RUN_DIRECTORY/ui-runner-signature.txt"
codesign -dvvv "$UI_TEST_APP/PlugIns/RunnerUITests.xctest" \
  2>&1 | tee "$RUN_DIRECTORY/ui-test-signature.txt"
XCTESTRUN_PATH="$(python3 - "$DERIVED_DATA/Build/Products" <<'PY'
from pathlib import Path
import sys
paths = list(Path(sys.argv[1]).glob('*.xctestrun'))
if len(paths) != 1:
    raise SystemExit(f'Expected one xctestrun, found {len(paths)}')
print(paths[0])
PY
)"
printf '%s\n' "$SIMULATOR_ID" > build/native-tests/simulator-id.txt
printf '%s\n' "$XCTESTRUN_PATH" > build/native-tests/xctestrun-path.txt
printf '%s\n' "$TEST_APP" > build/native-tests/integration-app-path.txt
python3 - "$TEST_APP" "$XCTESTRUN_PATH" <<'PY' | tee "$RUN_DIRECTORY/test-host.json"
import hashlib, json, plistlib, sys
from pathlib import Path
app, run = map(Path, sys.argv[1:])
with (app / 'Info.plist').open('rb') as source:
    info = plistlib.load(source)
assert info['CFBundleIdentifier'] == 'com.cleanupapp.cleaner'
assert info.get('NSPhotoLibraryUsageDescription')
assert info.get('NSPhotoLibraryAddUsageDescription')
with run.open('rb') as source:
    configuration = plistlib.load(source)
def test_paths(value):
    if isinstance(value, dict):
        row = {key: value[key] for key in ('TestHostPath', 'TestBundlePath', 'UITargetAppPath') if key in value}
        if row:
            yield row
        for child in value.values():
            yield from test_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from test_paths(child)
paths = list(test_paths(configuration))
bundles = [row.get('TestBundlePath', '') for row in paths]
assert any(path.endswith('/RunnerTests.xctest') for path in bundles), 'Unit test bundle is missing from xctestrun'
assert any(path.endswith('/RunnerUITests.xctest') for path in bundles), 'UI authorization test bundle is missing from xctestrun'
assert any(row.get('UITargetAppPath', '').endswith('/Runner.app') for row in paths), 'UI test target app is missing from xctestrun'
# The one compiled host contains the real integration entrypoint. XCTest must
# suppress its Dart scan while native fixtures/authorization run; flutter drive
# subsequently launches the same signed binary without this process environment.
def fixture_environment(value):
    if isinstance(value, dict):
        if 'TestBundlePath' in value:
            value.setdefault('EnvironmentVariables', {})['CLEANUP_NATIVE_FIXTURE_ONLY'] = '1'
            if value.get('IsUITestBundle') or 'UITargetAppPath' in value:
                value.setdefault('UITargetAppEnvironmentVariables', {})['CLEANUP_NATIVE_FIXTURE_ONLY'] = '1'
        for child in list(value.values()):
            fixture_environment(child)
    elif isinstance(value, list):
        for child in value:
            fixture_environment(child)
fixture_environment(configuration)
# Keep the xctestrun beside its original products: __TESTROOT__ paths are relative
# to this file, so copying it into the log directory would point at the wrong host.
with run.open('wb') as destination:
    plistlib.dump(configuration, destination)
print(json.dumps({'app': str(app), 'bundle_id': info['CFBundleIdentifier'],
    'executable_sha256': hashlib.sha256((app / info['CFBundleExecutable']).read_bytes()).hexdigest(),
    'xctestrun': str(run), 'test_paths': paths}, indent=2))
PY
xcrun simctl install "$SIMULATOR_ID" "$TEST_APP"
APP_DATA="$(xcrun simctl get_app_container "$SIMULATOR_ID" com.cleanupapp.cleaner data)"
mkdir -p "$APP_DATA/Documents"
printf 'cleanup-native-fixture-mode-v1\n' > "$APP_DATA/Documents/cleanup-native-fixture-mode"
printf '%s\n' "$APP_DATA/Documents/cleanup-native-fixture-mode" | tee "$RUN_DIRECTORY/fixture-mode-marker-path.txt"
# Reset only the disposable CI simulator. The UI test must respond to the real
# modern full-access prompt; simctl's legacy grant is deliberately not used.
xcrun simctl privacy "$SIMULATOR_ID" reset photos-add com.cleanupapp.cleaner
xcrun simctl privacy "$SIMULATOR_ID" reset photos com.cleanupapp.cleaner
xcrun simctl get_app_container "$SIMULATOR_ID" com.cleanupapp.cleaner app \
  | tee "$RUN_DIRECTORY/installed-host-path.txt"
record_photos_permission() {
  python3 - "$SIMULATOR_ID" "$1" <<'PY' | tee "$RUN_DIRECTORY/permission-$1.json"
import json, sqlite3, sys
from pathlib import Path
database = Path.home() / 'Library/Developer/CoreSimulator/Devices' / sys.argv[1] / 'data/Library/TCC/TCC.db'
result = {'phase': sys.argv[2], 'database_exists': database.exists()}
if database.exists():
    try:
        with sqlite3.connect(database.as_uri() + '?mode=ro', uri=True, timeout=3) as connection:
            available = {row[1] for row in connection.execute('PRAGMA table_info(access)')}
            columns = [name for name in ('client', 'client_type', 'service', 'auth_value', 'auth_reason', 'auth_version', 'flags', 'last_modified')
                       if name in available]
            query = 'SELECT ' + ', '.join(columns) + ' FROM access WHERE client = ? AND service LIKE ?'
            result['records'] = [dict(zip(columns, row)) for row in connection.execute(
                query, ('com.cleanupapp.cleaner', '%Photos%'))]
    except sqlite3.Error as error:
        result['read_error'] = str(error)
print(json.dumps(result, indent=2))
PY
}
record_photos_permission before-test
# Capture the isolated simulator during any authorization wait.
(
  sleep 30
  python3 - "$SIMULATOR_ID" "$RUN_DIRECTORY/authorization-screen.png" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'io', sys.argv[1], 'screenshot', sys.argv[2]],
               check=True, timeout=15)
PY
) &
SCREENSHOT_CAPTURE=$!
TEST_EXIT=0
# Use the same compiled product and simulator for both stages. Never run the
# unit fixture tests unless the real full-access UI bootstrap has succeeded.
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN_PATH" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -only-testing:RunnerUITests \
  -resultBundlePath "$RUN_DIRECTORY/PhotosAuthorization.xcresult" \
  2>&1 | tee "$RUN_DIRECTORY/xcodebuild-authorization.log" || TEST_EXIT=$?
record_photos_permission after-authorization || true
if [[ "$TEST_EXIT" == "0" ]]; then
  xcodebuild test-without-building \
    -xctestrun "$XCTESTRUN_PATH" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -destination-timeout 120 \
    -parallel-testing-enabled NO \
    -only-testing:RunnerTests/RunnerTests \
    -resultBundlePath "$RUN_DIRECTORY/Runner.xcresult" \
    2>&1 | tee "$RUN_DIRECTORY/xcodebuild.log" || TEST_EXIT=$?
  if [[ "$TEST_EXIT" == "0" ]]; then
    python3 - "$RUN_DIRECTORY/xcodebuild.log" <<'PY' || TEST_EXIT=$?
from pathlib import Path
import sys
log = Path(sys.argv[1]).read_text(errors='replace')
if 'real large Photos library finds exact copies and large movies' in log:
    raise SystemExit('Native XCTest unexpectedly ran the Dart Photos scan before its seeded integration stage.')
if 'CLEANUP_NATIVE_FIXTURE_MODE active' not in log:
    raise SystemExit('Native XCTest did not confirm the Dart fixture-only marker branch.')
print('Native XCTest host confirmed fixture-only Dart startup; no premature Flutter scan.')
PY
  fi
else
  echo "Photos authorization UI test failed; native fixture tests were not run."
fi
wait "$SCREENSHOT_CAPTURE" || true
record_photos_permission after-test || true
xcrun simctl spawn "$SIMULATOR_ID" log show --style compact --last 5m --info --debug \
  --predicate 'process == "tccd" OR process == "photolibraryd" OR process == "assetsd" OR process == "Runner"' \
  > "$RUN_DIRECTORY/simulator-photos-system.log" 2>&1 || true
/usr/bin/log show --style compact --last 5m --info --debug \
  --predicate 'process == "tccd" AND (eventMessage CONTAINS "Runner" OR eventMessage CONTAINS "cleanup" OR eventMessage CONTAINS "Simulator")' \
  > "$RUN_DIRECTORY/host-tcc-system.log" 2>&1 || true
exit "$TEST_EXIT"
