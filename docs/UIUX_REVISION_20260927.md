# UI/UX and 19-language revision — 2026-09-27

The Build 43 review found inaccessible swipe actions, a subscription retry that did not refresh customer info, confusing scan stages, and photo decisions buried beneath status panels. This revision implements all 24 review recommendations and adds regression coverage for the affected flows.

| Before | After | Why |
| --- | --- | --- |
| Scan progress reused historical attempts across size and SHA work | Each original-resource round has its own target, queue total and processed count; verified results remain separate | A size pass cannot make a later photo SHA pass appear complete |
| New installation opened an empty review page before scanning | Home has one real scan action; loaded results lead to review with optional continued analysis | The first action starts useful work |
| Rejected access had no recovery action; limited access could become stale | Settings and limited-library management actions, deferred foreground refresh, bounded metadata-only scope checks | Unchanged scope preserves progress; changed or unreadable scope clears stale results |
| Results competed with large technical notices | Compact check status, expandable details, larger grouped photos and clearer selection/preview controls | Photos become the main comparison workspace |
| Missing previews could be marked for deletion | Only decoded previews can be selected; final review removes unreadable items and validates the current ID/version/snapshot | Unseen or stale assets cannot enter a native deletion request |
| Final confirmation could not edit the deletion list | Shared review supports full photo/video preview and removal, plus an explicit warning for every version of a group | Users can fix an accidental selection before the Photos confirmation |
| Swipe had inaccessible actions, cropped cards and no saved decisions | Real semantic tap actions, fixed operation footer, contain previews, 150ms flick/rebound, local resume/reset and month/batch tools | Repetitive review stays discoverable and can continue across sessions |
| Videos were static covers; compression comparison restarted | Free original playback/seek, duration badges, shared controls and comparison at the same position | Users can judge the relevant part before deleting or saving a compressed copy |
| Retry refreshed prices without recovering Pro | Independently refresh customer info and offerings; unknown subscription state stays distinct from confirmed free | Existing subscribers are not misclassified after a transient lookup failure |
| Onboarding immediately led into payment/tracking | Skip/free-start persist completion and open Home; paywall shows actual SDK price/period and distinct loading/purchase/restore states | Users first see free value and understand later subscription actions |
| Settings showed free before verification and lacked management | Checking/unknown/free/Pro states, retry, restore, Apple subscription management and selected-language positioning | Account recovery and language switching are clear |
| Localization completeness did not prove the exported package | 19 languages × 361 messages, ICU/placeholder/native checks, packaged IPA/app resource and minimum-OS gate | Source and exported native permission languages are both verified |

The 19 explicit languages are Arabic, English, French, German, Hebrew, Indonesian, Italian, Japanese, Korean, Polish, Portuguese, Romanian, Russian, Simplified Chinese, Spanish, Thai, Turkish, Vietnamese and Traditional Chinese. The generated base Chinese alias is not a twentieth product language. Arabic/Hebrew dynamic prices and dimensions have bidi isolation; physical swipe directions remain left-to-mark-delete and right-to-keep.

Review decisions store only local asset IDs, modification versions and keep/delete choices. Each category retains the most recent 20,000 decisions, with the limit visible in the batch sheet. A live session can review a larger library, but older decisions can reappear after reopening. Restoring decisions never deletes media. Normal disposal flushes queued writes; abrupt termination can lose the pending 500ms debounce window. Month/batch review is available for larger libraries.

Unknown device capacity is never replaced by fabricated values. Home totals only confirmed media bytes; those are not a promise of immediately reclaimed system storage. Visual similarity remains a candidate relation; exact duplicate groups require verified full-content SHA. Preview scans and original checks keep separate bounded rounds, and unresolved cloud resources stay pending.

Validation commands:

The final local run passed 502 Flutter tests, 24 Python checker tests and `flutter analyze` with zero issues. This includes a 42,683-asset service workload, current-scope/version deletion guards, actual semantic swipe actions, and all supported locale entries at 200% text on a 320×568 viewport with fixed footer bounds and hit-testing.

```text
flutter gen-l10n
python scripts/check_localizations.py --escape-dart-isolates
python -m unittest discover -s scripts -p "test_check*.py"
flutter analyze
flutter test
```

The iOS release workflow additionally runs native Photos tests and genuine simulator libraries with 1,052 / 10,502 self-owned JPEG/H.264 fixtures. The integration flow checks exact duplicates, real file bytes, cancellation/continuation, original playback and hit-tested seeking before exporting the IPA. An exported-package check then compares all 19 native permission resources against ARB and verifies iPhone/iPad and iOS 13 support before TestFlight upload.

Physical VoiceOver focus, real StoreKit transactions, native speakers' language review, iCloud/Live Photo/RAW/HDR, low-storage behavior, temperature and real-device gesture performance remain device acceptance tasks. Widget renders and locally seeded simulator libraries do not establish those outcomes.
