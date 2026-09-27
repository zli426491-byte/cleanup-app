#!/usr/bin/env bash
set -euo pipefail

# Run after test-ios-native.sh on its exact, genuinely authorized simulator.
# Never reset Photos permission, grant legacy access, uninstall, or delete media.
WORKLOAD="${1:?Specify the real photo workload: 1000 or 10000}"
case "$WORKLOAD" in 1000|10000) ;; *) echo "Unsupported Photos workload" >&2; exit 2 ;; esac
SIMULATOR_ID="$(cat build/native-tests/simulator-id.txt)"
XCTESTRUN_PATH="$(cat build/native-tests/xctestrun-path.txt)"
test -n "$SIMULATOR_ID"
test -f "$XCTESTRUN_PATH"
test -f integration_test/photo_library_scan_test.dart
RESULT_DIRECTORY="$PWD/build/photo-library-tests/$WORKLOAD"
mkdir -p "$RESULT_DIRECTORY"
printf '%s\n' "$SIMULATOR_ID" > "$RESULT_DIRECTORY/simulator-id.txt"

# Bulk fixtures are separate real XCTest cases. Neither stage can silently skip
# or pass without actual Photos creation and production resource inspections.
TEST_EXIT=0
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN_PATH" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  "-only-testing:RunnerTests/PhotoLibrarySeedTests/testSeed${WORKLOAD}RealPhotoLibrary" \
  -resultBundlePath "$RESULT_DIRECTORY/PhotosSeed.xcresult" \
  2>&1 | tee "$RESULT_DIRECTORY/xcodebuild-seed.log" || TEST_EXIT=$?

# Preserve a complete manifest even on failure when an earlier stage exists.
APP_DATA="$(xcrun simctl get_app_container "$SIMULATOR_ID" com.cleanupapp.cleaner data)" || true
if [[ -f "$APP_DATA/Documents/cleanup-scan-fixtures.json" ]]; then
  cp "$APP_DATA/Documents/cleanup-scan-fixtures.json" "$RESULT_DIRECTORY/seed-manifest.json" || true
fi
if [[ "$TEST_EXIT" != "0" ]]; then
  echo "Real Photos seed failed; Flutter integration was not run."
  exit "$TEST_EXIT"
fi
test -f "$RESULT_DIRECTORY/seed-manifest.json"

# A 10k-ID JSON exceeds macOS's per-process argument budget after base64. Keep
# the full manifest in artifacts and pass only the independently checked roles.
MANIFEST_BASE64="$(python3 - "$RESULT_DIRECTORY/seed-manifest.json" "$WORKLOAD" "$RESULT_DIRECTORY/compact-manifest.json" <<'PY'
import base64, json, sys
from pathlib import Path
manifest = json.loads(Path(sys.argv[1]).read_text())
workload = int(sys.argv[2])
assert manifest['owner'] == 'cleanup-native-photos-integration-v1'
assert manifest['schemaVersion'] == 1 and manifest['status'] == 'native_verified'
assert manifest['stage'] == workload and manifest['workloadCount'] == workload
ids = manifest['allFixtureIds']
assert len(ids) == len(set(ids)) == manifest['actualFixtureCount'] == workload + 2
assert len(manifest['photoFixtureIds']) == workload
assert len(manifest['duplicateIds']) == 2 and len(manifest['differentPhotoIds']) == 6
assert len(manifest['largeVideoIds']) == 2
marked = manifest['duplicateIds'] + manifest['differentPhotoIds'] + manifest['largeVideoIds']
assert len(set(marked)) == 10 and set(marked) <= set(ids)
results = manifest['nativeResultsById']
for asset in marked:
    result = results[asset]
    assert result['complete'] and result['sizeKnown'] and result['sizeComplete']
    assert result['size'] == manifest['assetBytes'][asset] > 0
    is_photo = asset not in manifest['largeVideoIds']
    assert result['hashComplete'] == is_photo
    if is_photo:
        assert len(result.get('hash', '')) == 64
    else:
        assert 'hash' not in result
assert results[manifest['duplicateIds'][0]]['hash'] == results[manifest['duplicateIds'][1]]['hash']
different = {results[asset]['hash'] for asset in manifest['differentPhotoIds']}
assert len(different) == 6 and results[manifest['duplicateIds'][0]]['hash'] not in different
assert manifest['assetBytes'][manifest['largeVideoIds'][0]] > 5 * 1024 * 1024
assert manifest['assetBytes'][manifest['largeVideoIds'][1]] > 64 * 1024 * 1024
keys = ('schemaVersion', 'stage', 'workloadCount', 'actualFixtureCount', 'duplicateIds',
        'differentPhotoIds', 'largeVideoIds', 'fixtureRoleCounts')
compact = {key: manifest[key] for key in keys}
compact['assetBytes'] = {asset: manifest['assetBytes'][asset] for asset in marked}
encoded = json.dumps(compact, separators=(',', ':')).encode()
Path(sys.argv[3]).write_bytes(encoded)
argument = base64.b64encode(encoded).decode()
assert len(argument) < 100000
print(argument)
PY
)"

# Match the native test host's ad-hoc signing identity on reinstall. These are
# simulator-only build flags and require no Apple account or signing credentials.
FLUTTER_XCODE_CODE_SIGNING_ALLOWED=YES \
FLUTTER_XCODE_CODE_SIGNING_REQUIRED=YES \
FLUTTER_XCODE_CODE_SIGNING_IDENTITY=- \
FLUTTER_XCODE_CODE_SIGN_STYLE=Manual \
FLUTTER_XCODE_DEVELOPMENT_TEAM= \
flutter test integration_test/photo_library_scan_test.dart \
  -d "$SIMULATOR_ID" \
  --dart-define="CLEANUP_FIXTURE_MANIFEST_B64=$MANIFEST_BASE64" \
  2>&1 | tee "$RESULT_DIRECTORY/flutter-integration.log" || TEST_EXIT=$?

# Flutter integration_test owns these machine-readable assertions/screenshots.
# Reports list only the marked, owned simulator fixture IDs, not user photos.
APP_DATA="$(xcrun simctl get_app_container "$SIMULATOR_ID" com.cleanupapp.cleaner data)" || true
for SOURCE in \
  "$APP_DATA/Documents/cleanup-library-test-$WORKLOAD.json" \
  "$APP_DATA/Documents/photos-$WORKLOAD-exact.png" \
  "$APP_DATA/Documents/photos-$WORKLOAD-large.png"; do
  if [[ -f "$SOURCE" ]]; then cp "$SOURCE" "$RESULT_DIRECTORY/" || true; fi
done
if [[ "$TEST_EXIT" == "0" ]]; then
  test -s "$RESULT_DIRECTORY/cleanup-library-test-$WORKLOAD.json"
  test -s "$RESULT_DIRECTORY/photos-$WORKLOAD-exact.png"
  test -s "$RESULT_DIRECTORY/photos-$WORKLOAD-large.png"
fi
xcrun simctl io "$SIMULATOR_ID" screenshot "$RESULT_DIRECTORY/final-screen.png" || true
printf '{"workloadCount":%s,"exitCode":%s}\n' "$WORKLOAD" "$TEST_EXIT" > "$RESULT_DIRECTORY/harness-result.json"
exit "$TEST_EXIT"
