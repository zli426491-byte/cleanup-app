param(
    [string]$Flutter = "C:\Users\AsusGaming\flutter-sdk\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "== Flutter analyze =="
& $Flutter analyze

Write-Host "== Flutter test =="
& $Flutter test

Write-Host "== iOS Info.plist parse =="
@'
import plistlib
from pathlib import Path

plist = Path("ios/Runner/Info.plist")
data = plistlib.loads(plist.read_bytes())
required = [
    "NSPhotoLibraryUsageDescription",
    "NSUserTrackingUsageDescription",
]
missing = [key for key in required if not data.get(key)]
if missing:
    raise SystemExit(f"Missing plist keys: {', '.join(missing)}")
print("OK")
'@ | python -

Write-Host "== Android media permissions =="
$manifest = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
$requiredPermissions = @(
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"
)
foreach ($permission in $requiredPermissions) {
    if ($manifest -notmatch [regex]::Escape($permission)) {
        throw "Missing Android permission: $permission"
    }
}
Write-Host "OK"

Write-Host "== Done =="
