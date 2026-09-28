"""Validate Android release inputs and install the persistent upload keystore."""

import argparse
import base64
import binascii
import os
import sys
from pathlib import Path
from typing import Mapping, Optional


REQUIRED_ENV = (
    "REVENUECAT_ANDROID_API_KEY",
    "ANDROID_UPLOAD_KEYSTORE_BASE64",
    "ANDROID_RELEASE_KEYSTORE_PASSWORD",
    "ANDROID_RELEASE_KEY_ALIAS",
    "ANDROID_RELEASE_KEY_PASSWORD",
)


def validate_inputs(env: Mapping[str, str]) -> None:
    missing = [name for name in REQUIRED_ENV if not env.get(name, "").strip()]
    if missing:
        raise ValueError("Missing Android release credential(s): " + ", ".join(missing))
    if env["REVENUECAT_ANDROID_API_KEY"].strip().startswith("YOUR_"):
        raise ValueError("REVENUECAT_ANDROID_API_KEY is a placeholder")


def decode_keystore(encoded: str) -> bytes:
    try:
        data = base64.b64decode("".join(encoded.split()), validate=True)
    except binascii.Error as error:
        raise ValueError("ANDROID_UPLOAD_KEYSTORE_BASE64 is not valid base64") from error
    if not data:
        raise ValueError("ANDROID_UPLOAD_KEYSTORE_BASE64 decodes to an empty file")
    return data


def prepare_release(
    env: Mapping[str, str], keystore: Path, env_file: Optional[Path] = None
) -> None:
    validate_inputs(env)
    if env_file is None:
        github_env = env.get("GITHUB_ENV", "")
        if not github_env:
            raise ValueError("An environment file is required for the release workflow")
        env_file = Path(github_env)
    data = decode_keystore(env["ANDROID_UPLOAD_KEYSTORE_BASE64"])
    keystore.parent.mkdir(parents=True, exist_ok=True)
    keystore.write_bytes(data)
    keystore.chmod(0o600)
    with env_file.open("a", encoding="utf-8") as output:
        output.write(f"ANDROID_RELEASE_KEYSTORE_PATH={keystore}\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keystore", required=True, type=Path)
    parser.add_argument("--env-file", type=Path, help="Codemagic CM_ENV path")
    args = parser.parse_args()
    try:
        prepare_release(os.environ, args.keystore, args.env_file)
    except (OSError, ValueError) as error:
        print(f"Android release preparation failed: {error}", file=sys.stderr)
        return 1
    print("Android release credentials are present; upload keystore prepared.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
