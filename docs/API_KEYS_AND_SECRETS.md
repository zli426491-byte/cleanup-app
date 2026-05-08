# API Keys and Build Secrets

Do not commit real API keys, `.p8` files, Firebase config files, certificates, or private keys.

## Required Before Paid Traffic

Add these as GitHub Actions repository secrets and Codemagic secure environment variables:

| Secret name | Used by | Notes |
| --- | --- | --- |
| `REVENUECAT_IOS_API_KEY` | Flutter iOS build | Public SDK key from RevenueCat, still keep it out of source control. |
| `REVENUECAT_ANDROID_API_KEY` | Flutter Android build | Public SDK key from RevenueCat, still keep it out of source control. |
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

If a RevenueCat key is omitted or empty, the app will show a subscription setup warning instead of trying to initialize RevenueCat with an invalid key.

## App Store Connect Still Needed

The App Store Connect API currently reports the weekly and yearly subscriptions as `MISSING_METADATA`. Complete subscription metadata, localization, review screenshot, and pricing before approving any ad spend.
