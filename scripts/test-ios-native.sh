#!/usr/bin/env bash
set -euo pipefail

# Prepare Flutter's generated configuration and plugin workspace for XCTest.
flutter build ios --simulator --debug --no-codesign

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
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" build/ios/iphonesimulator/Runner.app
# Tests use a disposable simulator photo library, with no permission alert.
xcrun simctl privacy "$SIMULATOR_ID" grant photos com.cleanupapp.cleaner

mkdir -p build/native-tests
RUN_DIRECTORY="$(mktemp -d build/native-tests/run.XXXXXX)"
xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -only-testing:RunnerTests \
  -resultBundlePath "$RUN_DIRECTORY/Runner.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$RUN_DIRECTORY/xcodebuild.log"
