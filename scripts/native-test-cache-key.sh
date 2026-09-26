#!/usr/bin/env bash
set -euo pipefail

# Only compiler inputs belong in this key. Authorization/diagnostic shell changes
# can reuse the exact compiled test product. Bump this prefix if build flags change.
python3 - <<'PY'
import fnmatch
import hashlib
import json
import subprocess
from pathlib import Path

root = Path.cwd()

def command(*arguments):
    return subprocess.check_output(arguments, text=True).strip()

toolchain = {
    "xcode": command("xcodebuild", "-version"),
    "simulator_sdk": command("xcodebuild", "-version", "-sdk", "iphonesimulator"),
    "swift": command("xcrun", "swift", "--version"),
    "flutter": command("flutter", "--version", "--machine"),
    "host_architecture": command("uname", "-m"),
    "macos_version": command("sw_vers", "-productVersion"),
    "macos_build": command("sw_vers", "-buildVersion"),
}
flags = {
    "configuration": "Debug",
    "sdk": "iphonesimulator",
    "scheme": "Runner",
    "test_target": "RunnerTests",
    "ARCHS": toolchain["host_architecture"],
    "ONLY_ACTIVE_ARCH": "YES",
    "CODE_SIGNING_ALLOWED": "YES",
    "CODE_SIGNING_REQUIRED": "YES",
    "CODE_SIGNING_IDENTITY": "-",
    "CODE_SIGN_STYLE": "Manual",
    "DEVELOPMENT_TEAM": "",
}
paths = set(path for path in root.glob("pubspec*") if path.is_file())
inputs = (
    "lib", "assets", "ios/Runner", "ios/RunnerTests",
    "ios/Runner.xcodeproj", "ios/Runner.xcworkspace", "ios/Flutter",
    "ios/Podfile", "ios/Podfile.lock",
)
missing = []
for name in inputs:
    path = root / name
    if path.is_dir():
        paths.update(item for item in path.rglob("*") if item.is_file())
    elif path.is_file():
        paths.add(path)
    else:
        missing.append(name)

def source_input(path):
    relative = path.relative_to(root)
    if "xcuserdata" in relative.parts or "ephemeral" in relative.parts:
        return False
    if fnmatch.fnmatch(path.name, "Generated*.xcconfig"):
        return False
    if relative.as_posix() == "ios/Flutter/flutter_export_environment.sh":
        return False
    return path.name != ".DS_Store" and path.suffix != ".xcuserstate"

sources = {
    path.relative_to(root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
    for path in sorted(paths) if source_input(path)
}
manifest = {
    "cache_version": "v1-adhoc-active",
    "toolchain": toolchain,
    "compile_flags": flags,
    "sources": sources,
    "absent_inputs": sorted(missing),
}
encoded = json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()
key = "native-products-v1-adhoc-active-" + hashlib.sha256(encoded).hexdigest()
manifest["key"] = key
output = root / "build/native-tests/cache-inputs.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(key)
PY
