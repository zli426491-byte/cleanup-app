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
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_IDENTITY=
)
# Build once for the selected simulator. Test the exact same installed product.
xcodebuild build-for-testing "${XCODE_ARGUMENTS[@]}" \
  2>&1 | tee "$RUN_DIRECTORY/xcodebuild-build.log"
python3 - "$SIMULATOR_ID" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'bootstatus', sys.argv[1], '-b'],
               check=True, timeout=180)
PY
TEST_APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Runner.app"
test -d "$TEST_APP"
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
TEST_EXIT=0
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN_PATH" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -only-testing:RunnerTests \
  -resultBundlePath "$RUN_DIRECTORY/Runner.xcresult" \
  2>&1 | tee "$RUN_DIRECTORY/xcodebuild.log" || TEST_EXIT=$?
record_photos_permission after-test
exit "$TEST_EXIT"
