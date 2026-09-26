#!/usr/bin/env bash
set -euo pipefail

# Prepare Flutter's generated configuration and Pods without building a second
# app whose reinstall could invalidate the simulator's Photos permission.
mkdir -p build/native-tests
RUN_DIRECTORY="$(mktemp -d build/native-tests/run.XXXXXX)"
DERIVED_DATA="$PWD/build/native-test-derived-data"
flutter build ios --simulator --debug --no-codesign --config-only \
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
  -only-testing:RunnerTests \
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
test -d "$TEST_APP"
# Verify ad-hoc identity before installing. Simulator signatures use no account
# credentials and do not change the release IPA's signing configuration.
codesign --verify --strict "$TEST_APP"
codesign -dvvv "$TEST_APP" 2>&1 | tee "$RUN_DIRECTORY/host-signature.txt"
codesign -dr - "$TEST_APP" 2>&1 | tee "$RUN_DIRECTORY/host-requirement.txt"
codesign -dvvv "$TEST_APP/PlugIns/RunnerTests.xctest" \
  2>&1 | tee "$RUN_DIRECTORY/test-signature.txt"
XCTESTRUN_PATH="$(python3 - "$DERIVED_DATA/Build/Products" <<'PY'
from pathlib import Path
import sys
paths = list(Path(sys.argv[1]).glob('*.xctestrun'))
if len(paths) != 1:
    raise SystemExit(f'Expected one xctestrun, found {len(paths)}')
print(paths[0])
PY
)"
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
        row = {key: value[key] for key in ('TestHostPath', 'TestBundlePath') if key in value}
        if row:
            yield row
        for child in value.values():
            yield from test_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from test_paths(child)
print(json.dumps({'app': str(app), 'bundle_id': info['CFBundleIdentifier'],
    'executable_sha256': hashlib.sha256((app / info['CFBundleExecutable']).read_bytes()).hexdigest(),
    'xctestrun': str(run), 'test_paths': list(test_paths(configuration))}, indent=2))
PY
xcrun simctl install "$SIMULATOR_ID" "$TEST_APP"
# These permissions are confined to the disposable CI simulator.
xcrun simctl privacy "$SIMULATOR_ID" reset photos-add com.cleanupapp.cleaner
xcrun simctl privacy "$SIMULATOR_ID" reset photos com.cleanupapp.cleaner
# Full Photos access includes fixture creation; do not replace it with add-only.
xcrun simctl privacy "$SIMULATOR_ID" grant photos com.cleanupapp.cleaner
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
            columns = [name for name in ('client', 'service', 'auth_value', 'auth_reason', 'flags', 'last_modified')
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
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN_PATH" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -only-testing:RunnerTests \
  -resultBundlePath "$RUN_DIRECTORY/Runner.xcresult" \
  2>&1 | tee "$RUN_DIRECTORY/xcodebuild.log" || TEST_EXIT=$?
wait "$SCREENSHOT_CAPTURE" || true
record_photos_permission after-test
xcrun simctl spawn "$SIMULATOR_ID" log show --style compact --last 5m --info --debug \
  --predicate 'process == "tccd" OR process == "photolibraryd"' \
  > "$RUN_DIRECTORY/simulator-photos-system.log" 2>&1 || true
/usr/bin/log show --style compact --last 5m --info --debug \
  --predicate 'process == "tccd" AND (eventMessage CONTAINS "Runner" OR eventMessage CONTAINS "cleanup" OR eventMessage CONTAINS "Simulator")' \
  > "$RUN_DIRECTORY/host-tcc-system.log" 2>&1 || true
exit "$TEST_EXIT"
