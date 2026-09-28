"""Guard Android release signing and subscription-key requirements."""

import base64
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import prepare_android_release as release


ROOT = Path(__file__).resolve().parents[1]


def valid_environment():
    return {
        "REVENUECAT_ANDROID_API_KEY": "goog_test_key",
        "ANDROID_UPLOAD_KEYSTORE_BASE64": base64.b64encode(b"test-keystore").decode(),
        "ANDROID_RELEASE_KEYSTORE_PASSWORD": "store-password",
        "ANDROID_RELEASE_KEY_ALIAS": "upload",
        "ANDROID_RELEASE_KEY_PASSWORD": "key-password",
    }


class AndroidReleaseContracts(unittest.TestCase):
    def test_every_release_credential_is_required(self):
        for name in release.REQUIRED_ENV:
            with self.subTest(name=name):
                env = valid_environment()
                env[name] = "  "
                with self.assertRaisesRegex(ValueError, name):
                    release.validate_inputs(env)

    def test_placeholder_and_invalid_keystore_are_rejected(self):
        env = valid_environment()
        env["REVENUECAT_ANDROID_API_KEY"] = "YOUR_REVENUECAT_ANDROID_API_KEY"
        with self.assertRaisesRegex(ValueError, "placeholder"):
            release.validate_inputs(env)
        with self.assertRaisesRegex(ValueError, "not valid base64"):
            release.decode_keystore("invalid!base64")
        with self.assertRaisesRegex(ValueError, "empty file"):
            release.decode_keystore("")

    def test_keystore_is_prepared_for_both_build_steps(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = valid_environment()
            env["GITHUB_ENV"] = str(root / "github-env")
            keystore = root / "upload.keystore"
            release.prepare_release(env, keystore)
            self.assertEqual(keystore.read_bytes(), b"test-keystore")
            self.assertEqual(
                (root / "github-env").read_text(encoding="utf-8"),
                f"ANDROID_RELEASE_KEYSTORE_PATH={keystore}\n",
            )

    def test_codemagic_can_persist_keystore_path_without_github_env(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = {**os.environ, **valid_environment()}
            env.pop("GITHUB_ENV", None)
            keystore = root / "upload.keystore"
            cm_env = root / "codemagic-env"
            result = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "scripts/prepare_android_release.py"),
                    "--keystore",
                    str(keystore),
                    "--env-file",
                    str(cm_env),
                ],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(keystore.read_bytes(), b"test-keystore")
            self.assertEqual(
                cm_env.read_text(encoding="utf-8"),
                f"ANDROID_RELEASE_KEYSTORE_PATH={keystore}\n",
            )

    def test_release_gradle_config_cannot_fall_back_to_debug_signing(self):
        gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
        self.assertNotIn('signingConfigs.getByName("debug")', gradle)
        self.assertIn('System.getenv("ANDROID_RELEASE_REQUIRE_SIGNING")', gradle)
        self.assertIn('signingConfig = signingConfigs.getByName("release")', gradle)
        for name in (
            "ANDROID_RELEASE_KEYSTORE_PATH",
            "ANDROID_RELEASE_KEYSTORE_PASSWORD",
            "ANDROID_RELEASE_KEY_ALIAS",
            "ANDROID_RELEASE_KEY_PASSWORD",
        ):
            self.assertIn(f'System.getenv("{name}")', gradle)

    def test_release_workflow_validates_before_building(self):
        workflow = (ROOT / ".github/workflows/android-release.yml").read_text(
            encoding="utf-8"
        )
        self.assertLess(
            workflow.index("python3 scripts/prepare_android_release.py"),
            workflow.index("flutter build apk --release"),
        )
        self.assertIn("ANDROID_RELEASE_REQUIRE_SIGNING: 'true'", workflow)
        for name in release.REQUIRED_ENV:
            self.assertIn("secrets." + name, workflow)

    def test_unsigned_ci_validation_uses_debug_output(self):
        workflow = (ROOT / ".github/workflows/build-ios.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("flutter build apk --debug", workflow)
        self.assertIn("build/app/outputs/flutter-apk/app-debug.apk", workflow)
        self.assertNotIn("flutter build apk --release", workflow)

    def test_codemagic_android_release_requires_credentials_and_signing(self):
        workflow = (ROOT / "codemagic.yaml").read_text(encoding="utf-8")
        android = workflow.split("  android-release:\n", 1)[1]
        self.assertIn("- android_release_credentials", android)
        self.assertLess(
            android.index("python3 scripts/prepare_android_release.py"),
            android.index("flutter build apk --release"),
        )
        self.assertIn('--env-file "$CM_ENV"', android)
        self.assertIn("ANDROID_RELEASE_REQUIRE_SIGNING=true", android)
        self.assertIn('REVENUECAT_ANDROID_API_KEY="$REVENUECAT_ANDROID_API_KEY"', android)


if __name__ == "__main__":
    unittest.main()
