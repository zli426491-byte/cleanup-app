# Prelaunch QA Gate

Do not approve paid traffic until every required item is checked on a real device.

## Build Gate

- `flutter analyze` passes with 0 issues.
- `flutter test` passes.
- iOS release/TestFlight build includes `REVENUECAT_IOS_API_KEY`.
- Android release build includes `REVENUECAT_ANDROID_API_KEY`.
- App Store Connect weekly and yearly subscriptions are no longer `MISSING_METADATA`.
- RevenueCat Offering contains the weekly and yearly packages used by the app.

## First-Run Flow

- Fresh install opens onboarding.
- Onboarding next/skip actions work.
- ATT prompt appears only after onboarding, before the paywall.
- Closing onboarding paywall lands on the main tab screen.
- Reopening the app does not show onboarding again.

## Photo Scan Flow

- Photo permission prompt appears when starting scan.
- Denying photo permission does not crash the app.
- Limited photo access works and shows only selected assets.
- Full access scan completes on a device with at least 500 photos.
- Duplicate, similar, screenshots, videos, blurry, dark, and large-file counts update after scan.
- Swipe Clean shows real thumbnails, not placeholder icons.

## Paywall and Subscription Flow

- Paywall displays localized App Store prices.
- Weekly and yearly plan selection changes the selected plan UI.
- Purchase button buys the selected package.
- Sandbox trial / subscription purchase unlocks Pro.
- Restore Purchases unlocks Pro for a sandbox account with an active purchase.
- Purchase cancel returns to paywall without unlocking Pro.
- Placeholder RevenueCat key shows a setup warning and does not attempt purchase.

## Delete Flow

- Non-Pro user tapping delete opens paywall.
- Pro user tapping delete gets a confirmation dialog.
- Confirmed deletion moves photos to Recently Deleted.
- Deleted items disappear from all scan categories.
- Estimated savings recalculates after deletion.

## Analytics Gate

At minimum, verify these events in the real analytics destination before traffic:

- `app_opened`
- `onboarding_started`
- `onboarding_completed`
- `paywall_shown`
- `paywall_closed`
- `scan_started`
- `scan_completed`
- `photos_deleted`
- `trial_started`
- `subscription_started`
- purchase revenue event

## Paid Traffic Gate

Paid traffic can start only after:

- The app has a TestFlight or App Store build that passes the full QA checklist.
- RevenueCat shows successful sandbox purchase and restore.
- Analytics receives scan, paywall, and purchase events.
- Daily stop-loss budget is written down before launch.
- At least six original ad scripts are ready, each with a clear hook, pain point, proof, offer, CTA, and success metric.
