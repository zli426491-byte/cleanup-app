# API Keys and Build Secrets

Do not commit real API keys, `.p8` files, Firebase config files, certificates, or private keys.

## Required Before Paid Traffic

Add the secrets needed by the release workflow you use. Both the GitHub and
Codemagic **Android Release** workflows require all five Android entries below.
In Codemagic, place them in the secure `android_release_credentials` variable
group used by `codemagic.yaml`.

| Secret name | Used by | Notes |
| --- | --- | --- |
| `REVENUECAT_IOS_API_KEY` | Flutter iOS build | Public SDK key from RevenueCat, still keep it out of source control. |
| `REVENUECAT_ANDROID_API_KEY` | Android release | Nonempty public SDK key from RevenueCat; the release workflow rejects a missing or placeholder value. |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Android release | Base64 of the persistent Android upload keystore file. Keep the original keystore backed up outside this repository. |
| `ANDROID_RELEASE_KEYSTORE_PASSWORD` | Android release | Password for that keystore. |
| `ANDROID_RELEASE_KEY_ALIAS` | Android release | Alias of the upload key inside that keystore. |
| `ANDROID_RELEASE_KEY_PASSWORD` | Android release | Password for that upload key. |
| `APP_STORE_CONNECT_ISSUER_ID` | GitHub iOS release | Already required by the release workflow. |
| `APP_STORE_CONNECT_KEY_ID` | GitHub iOS release | Already required by the release workflow. |
| `APP_STORE_CONNECT_API_KEY` | GitHub iOS release | Contents of the App Store Connect `.p8` key. |
| `CERTIFICATE_PRIVATE_KEY` | GitHub iOS release | Required by Codemagic CLI signing flow. |

## Optional Analytics Secrets

These should be added only after the SDKs are installed and configured:

| Secret name | Provider |
| --- | --- |
| `ADJUST_APP_TOKEN` | Adjust |
| `FACEBOOK_APP_ID` | Meta App Events |
| `FACEBOOK_CLIENT_TOKEN` | Meta App Events |

Firebase uses platform config files rather than a single API secret:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Keep production copies out of normal commits unless the team intentionally decides those files are acceptable for this repo. If committed, verify they do not contain private service-account credentials.

## Local Flutter Build Examples

iOS:

```bash
flutter build ipa --release \
  --dart-define=REVENUECAT_IOS_API_KEY=appl_xxx
```

Android:

```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxx
```

Without signing environment variables, local release builds are unsigned; debug
builds are unaffected. To sign locally, set `ANDROID_RELEASE_KEYSTORE_PATH` to
the same persistent keystore file and set `ANDROID_RELEASE_KEYSTORE_PASSWORD`,
`ANDROID_RELEASE_KEY_ALIAS`, and `ANDROID_RELEASE_KEY_PASSWORD`. Set
`ANDROID_RELEASE_REQUIRE_SIGNING=true` when an unsigned output must fail.

Both Android release workflows validate all five Android credentials before
building. They decode `ANDROID_UPLOAD_KEYSTORE_BASE64` into a temporary file;
GitHub uses the same upload key for its APK and AAB, while Codemagic produces a
signed APK. Generate the secret from the original keystore without committing
either the keystore or its base64 text; for example,
`base64 -w0 android-upload.keystore` on Linux.
Retain the original keystore and passwords so later releases can use the same
upload key. A missing key or signing input fails the workflow instead of
producing a debug-signed release artifact.

For non-release builds, an omitted RevenueCat key still shows a subscription
setup warning instead of trying to initialize RevenueCat with an invalid key.

## App Store Connect Still Needed

The App Store Connect API currently reports the weekly and yearly subscriptions as `MISSING_METADATA`. Complete subscription metadata, localization, review screenshot, and pricing before approving any ad spend.
