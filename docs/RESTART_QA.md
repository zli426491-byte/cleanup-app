# Restart acceptance — 2026-09-26

This checklist reflects the current photo-review build. The older PRELAUNCH_QA
describes features that are not included in this restart build.

## Confirmed by read-only backend checks

- App Store version 1.1.2 is READY_FOR_SALE.
- Version 1.1.3 is PREPARE_FOR_SUBMISSION.
- Build 37 (1.1.3) is VALID and not expired, with internal state IN_BETA_TESTING.
- The existing Internal Testing group includes build 37; external state is
  READY_FOR_BETA_SUBMISSION. No new tester invitations were sent.
- Weekly and yearly subscriptions are READY_TO_SUBMIT, not approved for sale.
- RevenueCat default offering returns the matching Apple weekly/yearly products.

## Automated checks

Run `scripts/preflight_check.ps1` before a new cloud build. It fails on analyze,
test, plist, or Android permission validation errors.

Coverage includes purchase/restore waiting past 12 seconds, cancellation and
concurrent purchases, partial scan disclosure, permission denial/limited access,
metadata matches treated as review candidates, and actual OS-confirmed deletion.
Mocks do not establish that real purchases or photo deletion work on a device.

## Real-device acceptance (iPhone and iPad)

- [ ] Fresh install shows photo-review onboarding; no dormant tool claims.
- [ ] Free scan and preview work; deleting opens paywall for non-Pro users.
- [ ] Denied and limited photo access give accurate, actionable results.
- [ ] 500 and 5,000+ asset libraries disclose the scan scope (maximum 900).
- [ ] iCloud-only thumbnails either load or show a clear fallback without hanging.
- [ ] Visually different images with matching metadata are never labelled verified duplicates.
- [ ] Photos are previewed before selection; cancelling OS deletion keeps selection.
- [ ] Only OS-confirmed deleted items disappear; a partial deletion shows its true count.
- [ ] Swipe card changes show the correct photo and require Pro before deletion.
- [ ] Weekly/yearly prices and periods match the device's StoreKit products.
- [ ] Sandbox purchase, cancellation, restore, expiry and renewal update Pro correctly.
- [ ] Tablet layout and native confirmation dialogs work in portrait and landscape.
- [ ] Privacy/EULA links work, and settings show the actual installed version/build.

## Release gates still outstanding

- [x] Upload build 37 using GitHub iOS Release; run 36250081707 succeeded.
      Local and cloud analyze passed, with all 24 tests passing in both.
      App code is commit 04296b3; these results were checked at
      2026-09-26T15:06:05Z. Real-device acceptance remains unchecked.
- [ ] Attach correct paywall review screenshots and subscriptions to the submission.
- [ ] Review all localized store descriptions/screenshots against the current scope.
- [ ] Connect a real product analytics destination and verify events arriving there.
- [ ] Verify real trial/charge/renewal/refund events via transaction data; do not infer
      revenue from a client `purchase_completed` event or displayed list price.
- [ ] Review current privacy disclosures for the final enabled SDKs.
- [ ] Receive App Review approval for app and subscriptions before paid acquisition.

## Scope explicitly deferred

Verified content-based duplicate detection, blurry/dark analysis, complete-library
background scanning, actual storage byte measurements, compression, contacts,
email/calendar cleanup, and vault security/import remain separate work items.
Legacy source/data is preserved; hidden features have not been deleted.
