# Restart acceptance — 2026-09-27

This checklist describes the new full-library photo-review and video-compression
candidate. The older PRELAUNCH_QA describes dormant tools and is not the release
scope. Build 38 remains a historical TestFlight baseline. The new Build 39 has
passed Mac CI and upload, is VALID, and is available in the existing internal
TestFlight group. Native-device acceptance remains required below.

## Backend baseline and build history

Read-only checks at 2026-09-26T15:35:50Z established:

- App Store version 1.1.2 is READY_FOR_SALE.
- Version 1.1.3 is PREPARE_FOR_SUBMISSION.
- Build 38 (1.1.3) is VALID, not expired, and IN_BETA_TESTING internally.
- The existing Internal Testing group includes build 38; external state is
  READY_FOR_BETA_SUBMISSION. No new tester invitations were sent.
- Weekly and yearly subscriptions are READY_TO_SUBMIT, not approved for sale.
- RevenueCat's default offering returns the matching Apple weekly/yearly products.
- Weekly availability includes the USA but excludes Taiwan; yearly includes both.
  Check the tester's actual StoreKit storefront rather than assuming both plans
  appear on every device.

Build 37 used commit 04296b3 and successful GitHub iOS Release run 36250081707;
local/cloud analyze and 24 tests passed. Build 38 used commit bef47ac and
successful run 36251714219; local/cloud analyze and 48 tests passed. Those
results apply to those builds, not to the candidate described below.

## Implemented candidate scope

- Scan all accessible photo/video IDs in pages without a fixed library-size cap.
  Reading and analysis show separate counts. Work can be cancelled and resumed
  within the app session; resuming reindexes accessible IDs and retains analyses
  only for unchanged items. Force-quitting the app is not a promised background
  continuation or persistent-resume feature.
- On iOS, the Photos resource bridge streams local resources in bounded chunks
  to measure their bytes. It does not enable iCloud downloads. Unknown resource
  types, incomplete resource reads, unavailable originals, and timeouts stay
  pending instead of becoming zero-byte measurements or duplicate evidence.
- True duplicate photo groups require a complete SHA-256 fingerprint of all
  original/current/adjustment resources. Live Photo paired movies and edited
  renders are included. Matching names, dates, dimensions, or thumbnails alone
  do not establish true duplication. These groups concern photo assets; video
  duplicate detection is not included.
- Visual similarity uses image evidence from bounded current thumbnails, not
  metadata buckets. Thumbnail-derived quality/brightness/sharpness measurements
  support reversible keep suggestions. A suggestion is neither a guarantee of
  visual quality nor an automatic deletion selection.
- Separate categories expose photos, true duplicates, visual similarity,
  screenshots, videos, and large files. Large files use measured resource bytes;
  unknown sizes display "容量未取得" and unavailable content displays pending.
  Measured resource bytes and actual device space reclaimed are different values.
- Users can enlarge previews, withdraw/re-display keep suggestions, and manually
  mark assets for deletion. Pro, app confirmation, native confirmation, actual
  OS-returned deletion IDs, and scan/delete mutual exclusion remain required.
- Pro video compression creates a separate preview with audio requested and the
  original retained. Users can compare original/output playback before explicit
  saving. The service checks readable output, measured size reduction, and
  reasonable duration agreement; sound, orientation, HDR/color, and subjective
  quality still require native-device checks. Cancellation, failed encoding,
  failed saves, and retry must not remove the original.
- Saving the compressed video adds a new Photos asset. The original is never
  automatically deleted. Saving twice must not create duplicate copies of the
  same prepared output; unresolved saves remain busy until their result settles.
- Contacts, email/calendar cleanup, vault/import, and charging demo remain hidden.
  Product analytics still needs a real destination before acquisition.

The resource bridge is iOS-specific. Non-iOS behavior must disclose unavailable
native resource analysis; do not claim Windows widget tests prove Photos reads,
native encoding, StoreKit, or actual deletion work.

## Automated and Mac CI gates

Run `scripts/preflight_check.ps1` before a new cloud build. It fails on analyze,
test, plist, or Android permission validation errors.

- [x] Candidate commit dac59c2: local preflight passes analyze with zero issues,
      all 97 tests, plist validation (including video save usage), and media
      permission checks. GitHub iOS Release run 36254933611 succeeded at commit
      dac59c2, with zero analyze issues and all 97 cloud tests passing.
- [x] Compile the Swift resource bridge on macOS, including its Runner target
      membership, registration, Photos APIs, CryptoKit, and video plugin linkage.
- [x] Run cloud analyze/tests and archive the candidate with the correct bundle
      ID, version, incremented build number, export options, and signing profile.
      Downloaded IPA is version 1.1.3 build 39, com.cleanupapp.cleaner, iPhone/iPad.
- [x] Verify GitHub's accepted TestFlight upload result and Apple's VALID build
      state/internal group visibility separately. Upload success alone is not
      native-device acceptance.
      Upload receipt aef90a08-4387-4c9a-892f-57cb9e9088ce was accepted; Apple
      processing state is VALID, internal state IN_BETA_TESTING, and the existing
      internal group includes it at 2026-09-26T16:30:22Z. External state is
      READY_FOR_BETA_SUBMISSION; no app/subscriptions were submitted for review.

Automated coverage should include libraries beyond the old partial-index range,
content fingerprints versus metadata coincidences, visual false positives,
quality suggestions, pending cloud resources, cancellation/resume, edit
invalidation, actual deletion IDs, and compression output/save/cancellation
races. Mocks cannot establish real native permission, photo/video behavior,
encoder output quality, billing, or storage recovery.

## iPhone and iPad native acceptance

Run on both iPhone and iPad, recording device/model, iOS version, installed build,
Photos permission, library size, and StoreKit storefront. Use expendable test
assets and check the Photos app after each destructive operation.

### Onboarding, layout, and subscriptions

- [ ] Fresh install completes the current onboarding; free scanning/previews work
      and destructive/paid operations open the paywall for a non-Pro account.
- [ ] Slow/offline startup still displays the app. Failed plans can be reloaded;
      product loading during an unfinished purchase/restore cannot unlock a
      second transaction. Repeated onboarding taps open one paywall.
- [ ] A free account has no PRO badge. Every home tool opens its matching category.
- [ ] Small-phone large text, phone portrait/landscape, iPad portrait/landscape,
      and small iPad multitasking windows keep content and controls reachable.
      Supported appearance remains light even with a dark system appearance.
- [ ] Privacy/EULA links work; settings show the actual installed version/build.
- [ ] Sandbox prices/periods match StoreKit products. Purchase, cancellation,
      restore, expiry, and renewal update Pro correctly on both device types.

### Full index, permissions, and continuation

- [ ] Use small and 5,000+ asset libraries. Compare all accessible IDs/counts with
      Photos; reaching a large count must not silently truncate the scan.
- [ ] Read count/total and analyzed/pending counts remain accurate during pages,
      analysis, cancellation, resume, empty libraries, and permission errors.
- [ ] Denied access gives an actionable message. Limited access indexes only the
      allowed assets. After changing the allowed set, resume/manual rescan drops
      inaccessible IDs and finds newly allowed ones.
- [ ] Cancel during indexing, an image resource read, a large video read, and
      thumbnail analysis. UI responds, retains settled results, starts no delete,
      and ignores stale completions. Resume preserves unchanged successful work
      and retries pending work without duplicate IDs/groups.
- [ ] Background/foreground and device lock do not hang the UI or turn incomplete
      work into completed analysis. If iOS suspends work, resume/manual rescan is
      available; do not assume full background execution.
- [ ] Delete/add/edit assets in Photos between scans. Resume/manual rescan updates
      the ID set and modified assets rather than reusing stale content evidence.
      External Photos changes currently require manual refresh.
- [ ] iCloud-only and partially downloaded assets stay pending without forced
      downloads. Download in Photos, then retry; the item becomes measured only
      after every required resource is available. Preview fallback can be retried
      on the same screen.

### True duplicates, similarity, sizes, and safe deletion

- [ ] Copies with exactly identical complete resource sets appear as true
      duplicates. Different pictures with matching dates/names/dimensions do not.
- [ ] Two assets with the same original but different edits/crops/filters remain
      distinct unless their complete resource fingerprints really match. Edited
      photos missing a current render remain pending. Edit after a scan and
      verify cached evidence is invalidated on resume/manual rescan.
- [ ] Live Photos with an identical still but different paired motion are not
      true duplicates. Missing paired video/current edited motion stays pending.
      RAW/alternate/adjustment resources must not be silently ignored.
- [ ] Visually similar re-encoded/resized photos may appear as visual similarity,
      while unrelated portraits, blank/solid-color images, and repetitive scenes
      do not become verified duplicates. Review borderline visual groups manually.
- [ ] Keep suggestions identify one candidate and explain the reason. Withdraw
      and re-display the suggestion without selecting/deleting any image; manual
      selection remains under the user's control and enlarging a preview works.
- [ ] Compare measured local resource bytes with the actual exported resources,
      including multi-resource Live/edited assets. Unknown/pending capacity never
      displays a fabricated 0 MB; large-file ranking uses real bytes, not pixels.
- [ ] Free deletion opens the paywall. Pro deletion previews selected items and
      requires both confirmations. Cancel keeps selections; only OS-confirmed
      IDs disappear. Partial/native failures show the actual count.
- [ ] Scan and native deletion cannot overlap. After swipe deletion, grid
      selections/counts refresh; cancelling permits retry. Undo before deletion
      changes the review decision and does not claim to restore deleted assets.

### Video compression, preview, saving, and cleanup

- [ ] Use portrait and landscape clips with speech/music, a silent clip, edited
      clips, short/long clips, HEVC/HDR where available, and a clip that cannot
      achieve a smaller output. An unsupported/invalid result is clearly rejected
      while the original remains playable in Photos.
- [ ] Confirm original/output length, beginning/end, seek/playback, sound,
      orientation, aspect ratio, color/HDR, and acceptable picture quality. The
      "include audio" encoder setting alone is not proof audio is preserved.
- [ ] Displayed original/output bytes match measured files. No savings claim is
      made when output is equal/larger, empty, unplayable, or materially shorter.
- [ ] An iCloud-only video gives the download-first guidance instead of silently
      forcing a transfer; after downloading the original in Photos, retry works.
- [ ] Cancel during loading/encoding and retry rapidly/repeatedly. Never run two
      native encoders at once; late output from a cancelled attempt cannot replace
      the latest preview. Native and app-owned temporary files are cleaned safely.
- [ ] Compare original and compressed playback before saving. Saving is permitted
      only with a usable output preview and active Pro. Repeated save taps and
      delayed callbacks create one copy; cancellation of compression does not
      cancel or repeat an already unresolved Photos save.
- [ ] Test revoked permission, insufficient space, save failure, cancellation,
      retry, and leaving the view. Original files stay intact; failures do not
      report success or clean up an output still being read by a native save.
- [ ] After successful save, Photos contains the new playable copy and the
      untouched original. Manual rescan finds the new copy and its real size.
      Saving adds storage use; deleting the original and clearing Recently
      Deleted is a separate user action. Actual free space is checked in Settings.

## Remaining release gates

### Build 39 scan-stall follow-up

On 2026-09-27 the iPhone test indexed 42,683 items but showed zero content
analyses. The user confirmed cancellation still returned to usable controls.
The pipeline waited for sequential complete original-resource streams before
requesting previews and committing a batch. This can starve visual progress;
the precise device Photos/iCloud condition is not captured in the screenshot.

- [x] Separate cached current-preview batches from explicit original verification.
      A preview never proves identical original content or measured resource size.
- [x] Bound a preview analysis round to 30 seconds and an original verification
      round to 60 seconds after indexing. Index all accessible items, with no
      fixed item cap. Resume unattempted items first, preserve hidden checkpoints
      across interrupted re-indexing, and invalidate edits/revoked access.
- [x] Use cancellable analysis isolates, cached progress counters, amortized
      snapshots, and bounded thumbnail memory. Wait heartbeats do not re-filter
      the whole library. Preview indexed media while scan mutation is disabled.
- [x] Native deadlines/results do not wait for the Photos state queue or native
      cancellation. Original reads stop at 4 seconds / 64 MiB by default;
      oversized, slow, cloud-only or incomplete material stays unverified.
- [x] Local preflight: zero analysis issues, all 112 Flutter tests, and plist /
      Android media-permission checks pass. Includes 42,683-item indexing,
      timeout-heavy scans, slow first resources, continuation fairness, late
      cancellation, interrupted re-indexing, and phone/iPad progress layouts.
- [x] Reduce worst-case candidate comparisons without changing the similarity
      thresholds: validate immutable features once and stop accumulating squared
      spatial differences once rejection is certain. Preserve public malformed
      input checks and the final floating-point boundary decision. Desktop AOT
      stress measurements for 42,683 shared-bucket, dissimilar signatures improve
      from about 13 seconds to about one second; result parity is checked. These
      measurements do not establish iPhone timing. The first Mac run was
      cancelled before signing/upload so this fix is included in the next run.
- [ ] Run all 10 native XCTest cases on the Mac CI simulator before signing and
      uploading the next internal build. Six use a real simulator Photos fixture;
      tests never create/delete fixture media on physical devices.
- [ ] Update iPhone and iPad to the next verified internal build and re-test the
      real 42,683-item library. Check processed/visual/cloud counts, previews,
      cancellation and continuation. Do not treat a 30-second analysis round as
      a promise that indexing or the whole library finishes in 30 seconds.

- [ ] Finish the candidate's Mac CI and iPhone/iPad checklist above before treating
      the new functionality as release-ready.
- [ ] Attach correct paywall review screenshots and subscriptions to submission.
- [ ] Review every localized description/screenshot against actual enabled scope.
- [ ] Connect product analytics and verify events arrive at the real destination.
- [ ] Verify trial/charge/renewal/refund through transaction data; do not infer
      revenue from client `purchase_completed` events or displayed list prices.
- [ ] Review final SDK/privacy disclosures and minimum supported iOS requirements.
- [ ] Receive app/subscription App Review approval before paid acquisition.

## Still outside this candidate

Guaranteed operating-system background scanning, persistent progress after
force-quit, automatic external-library refresh, device-storage/free-space
measurements, video duplicate detection, contacts, email/calendar cleanup, and
vault security/import remain separate work items. Thumbnail quality metrics
currently support review suggestions; no separate blurry/dark cleanup category
or perfect image-quality judgment is promised. Legacy source/data is preserved.
