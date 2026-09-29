import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/home/main_tab_view.dart';
import 'package:cleanup_app/views/v2/category_grid_view.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/components/video_playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Actual Photos/MethodChannel/Flutter integration on the disposable CI
/// simulator. No mock channels, fabricated sizes, deletion or StoreKit calls.
void main() {
  // Native XCTest and the real Photos authorization bootstrap share this exact
  // compiled app. They must not start Flutter scan tests before seeding Photos.
  // Dart's iOS runtime returns an empty Platform.environment. The CI harness
  // writes this marker into the app's persistent Documents directory before
  // native tests, then removes it before the normal prebuilt driver launch.
  // iOS's native TMPDIR identifies the adjacent tmp directory in this container.
  if (Platform.isIOS &&
      File(
        '${Directory.systemTemp.parent.path}/Documents/cleanup-native-fixture-mode',
      ).existsSync()) {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MaterialApp(home: SizedBox.shrink()));
    debugPrint(
      'CLEANUP_NATIVE_FIXTURE_MODE active tmp=${Directory.systemTemp.path}',
    );
    return;
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real large Photos library finds exact copies and large movies',
    (tester) async {
      expect(
        Platform.isIOS,
        isTrue,
        reason: 'Requires the isolated iOS simulator.',
      );
      final documents = await getApplicationDocumentsDirectory();
      final seedFile = File('${documents.path}/cleanup-scan-fixtures.json');
      expect(
        seedFile.existsSync(),
        isTrue,
        reason: 'A real native-verified Photos seed is mandatory.',
      );
      final manifest = jsonDecode(await seedFile.readAsString()) as Map;
      expect(manifest['owner'], 'cleanup-native-photos-integration-v1');
      expect(manifest['status'], 'native_verified');
      final workload = manifest['workloadCount'] as int;
      expect(manifest['stage'], workload);
      final actualCount = manifest['actualFixtureCount'] as int;
      expect(workload, anyOf(1000, 10000));
      final shortVideoCount = workload ~/ 20;
      expect(actualCount, workload + shortVideoCount + 2);
      final duplicateIds = List<String>.from(manifest['duplicateIds'] as List);
      final differentIds = List<String>.from(
        manifest['differentPhotoIds'] as List,
      );
      final movieIds = List<String>.from(manifest['largeVideoIds'] as List);
      final expectedBytes = Map<String, dynamic>.from(
        manifest['assetBytes'] as Map,
      );
      expect(duplicateIds.length, 2);
      expect(differentIds.length, greaterThanOrEqualTo(2));
      expect(movieIds.length, greaterThanOrEqualTo(2));
      expect(
        movieIds.map((id) => expectedBytes[id] as int),
        contains(greaterThan(64 * 1024 * 1024)),
      );

      final scanner = PhotoScannerService();
      final subscription = SubscriptionManager();
      final stages = <String, Object?>{};
      addTearDown(scanner.dispose);
      addTearDown(subscription.dispose);
      await _showHome(tester, scanner, subscription);

      final watch = Stopwatch()..start();
      final labels = AppLocalizations.of(tester.element(find.byType(HomeView)));
      if (!scanner.isScanning && scanner.scannedAssetCount == 0) {
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('home-scan-start')),
        );
      }
      await _waitUntil(
        tester,
        () => scanner.isScanning || scanner.scannedAssetCount > 0,
        'home scan start',
      );
      // The v2 Home checks originals on its own once previews finish. Leave
      // Home so this test can verify each original round separately in the
      // review tool, exactly as before.
      await _showTool(tester, scanner, subscription, null);
      // Continuous previews may legitimately run for minutes on a large
      // library. Opening a resource category pauses them and verifies the
      // requested originals, so only indexing must finish here.
      await _waitUntil(
        tester,
        () => scanner.scannedAssetCount >= actualCount,
        'home indexing end',
      );
      stages['initialIndexMs'] = watch.elapsedMilliseconds;
      expect(scanner.scannedAssetCount, greaterThanOrEqualTo(actualCount));
      expect(scanner.totalPhotoCount, greaterThanOrEqualTo(workload));
      expect(
        scanner.scanResult.videos.length,
        greaterThanOrEqualTo(shortVideoCount + 2),
      );
      expect(scanner.nativeOriginalAnalysisAvailable, isTrue);
      final indexed = scanner.scanResult.allAssets.map((a) => a.id).toSet();
      expect(
        indexed,
        containsAll([...duplicateIds, ...differentIds, ...movieIds]),
      );
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.knownSizeAssetCount, 0);
      stages['indexedCount'] = scanner.scannedAssetCount;
      stages['indexedPhotoCount'] = scanner.totalPhotoCount;
      stages['indexedVideoCount'] = scanner.scanResult.videos.length;
      stages['previewAnalyzedCount'] = scanner.analyzedAssetCount;
      stages['previewPendingCount'] = scanner.pendingAnalysisCount;

      // Ordinary category entry must produce data without a second button tap.
      watch.reset();
      await _showTool(tester, scanner, subscription, 'duplicates');
      expect(find.byType(SmartCleanView), findsOneWidget);
      await _waitUntil(
        tester,
        () =>
            scanner.originalVerificationTarget ==
            OriginalVerificationTarget.exactPhotos,
        'automatic exact start',
      );
      await _waitUntil(
        tester,
        () =>
            scanner.originalVerificationTarget ==
                OriginalVerificationTarget.exactPhotos &&
            !scanner.isScanning,
        'automatic exact end',
      );
      stages['automaticExactMs'] = watch.elapsedMilliseconds;
      // One 60-second round checks between ~350 and ~1,900 originals on CI
      // simulators, so a large library may need the user's "continue" CTA,
      // just like the size rounds below.
      var exactRounds = 1;
      while (!_hasExactPair(scanner, duplicateIds) && exactRounds < 6) {
        final verifiedBefore = scanner.verifiedHashAssetCount;
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('verify-originals-cta')).first,
        );
        await _waitUntil(
          tester,
          () => !scanner.isScanning,
          'continued exact round end',
        );
        exactRounds++;
        expect(
          scanner.verifiedHashAssetCount,
          greaterThanOrEqualTo(verifiedBefore),
          reason: 'A continued exact round must keep verified hashes.',
        );
        debugPrint(
          'PHOTO_EXACT_ROUND_$exactRounds '
          'verified=${scanner.verifiedHashAssetCount}',
        );
      }
      stages['exactRounds'] = exactRounds;
      _expectExactPair(scanner, duplicateIds, differentIds);
      stages['exactGroupCount'] = scanner.scanResult.duplicateGroups.length;
      stages['exactVerifiedPhotoCount'] = scanner.verifiedHashAssetCount;
      expect(
        scanner.originalVerificationTarget,
        OriginalVerificationTarget.exactPhotos,
      );
      expect(
        scanner.originalRoundTotal,
        lessThanOrEqualTo(scanner.totalPhotoCount),
      );
      expect(
        scanner.originalRoundProcessed,
        lessThanOrEqualTo(scanner.originalRoundTotal!),
      );
      final originalHash = {
        for (final id in duplicateIds)
          id: scanner.scanResult.allAssets.firstWhere((a) => a.id == id).hash,
      };
      final beforeLarge = {
        for (final asset in scanner.scanResult.allAssets) asset.id: asset,
      };
      await tester.pump(const Duration(milliseconds: 600));
      await _revealAsset(tester, duplicateIds.first);
      _expectActiveCategoryVisible(tester, labels.scanCategoryExact);
      await _capture(binding, 'photos-$workload-exact');

      watch.reset();
      await _showTool(tester, scanner, subscription, 'largeFiles');
      expect(find.byType(SmartCleanView), findsOneWidget);
      await _waitUntil(
        tester,
        () => scanner.isScanning || _hasMovies(scanner, movieIds),
        'automatic size start',
      );
      await _waitUntil(
        tester,
        () =>
            scanner.originalVerificationTarget ==
                OriginalVerificationTarget.fileSizes &&
            scanner.originalRoundTotal != null,
        'automatic size queue',
      );
      final sizeQueueStart = _sizeRoundDiagnostics(scanner, movieIds);
      stages['sizeQueueStart'] = sizeQueueStart;
      debugPrint('PHOTO_SIZE_QUEUE_START $sizeQueueStart');
      final metadataDriftAtSizeStart = _metadataDrift(
        beforeLarge,
        scanner.scanResult.allAssets,
      );
      stages['metadataDriftAtSizeStart'] = metadataDriftAtSizeStart;
      debugPrint(
        'PHOTO_CHECKPOINT_METADATA_DRIFT_AT_SIZE_START '
        '$metadataDriftAtSizeStart',
      );
      for (final entry in originalHash.entries) {
        final cached = scanner.scanResult.allAssets.firstWhere(
          (asset) => asset.id == entry.key,
        );
        expect(
          cached.sizeKnown,
          isTrue,
          reason: 'Exact-to-size re-index lost a verified photo byte count.',
        );
        expect(
          cached.hash,
          entry.value,
          reason: 'Exact-to-size re-index lost a verified SHA.',
        );
      }
      await _waitUntil(tester, () => !scanner.isScanning, 'automatic size end');
      stages['automaticLargeMs'] = watch.elapsedMilliseconds;
      final metadataDrift = _metadataDrift(
        beforeLarge,
        scanner.scanResult.allAssets,
      );
      stages['metadataDriftAfterExact'] = metadataDrift;
      debugPrint('PHOTO_CHECKPOINT_METADATA_DRIFT $metadataDrift');
      debugPrint(
        'PHOTO_SIZE_ROUND_1 ${_sizeRoundDiagnostics(scanner, movieIds)}',
      );
      var sizeRounds = 1;
      while (!_hasMovies(scanner, movieIds) && sizeRounds < 3) {
        final knownBefore = scanner.knownSizeAssetCount;
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('verify-originals-cta')),
        );
        await _waitUntil(
          tester,
          () => !scanner.isScanning,
          'continued size round end',
        );
        sizeRounds++;
        expect(
          scanner.knownSizeAssetCount,
          greaterThanOrEqualTo(knownBefore),
          reason: 'A retry must retain previously verified bytes.',
        );
        for (final entry in originalHash.entries) {
          expect(
            scanner.scanResult.allAssets
                .firstWhere((asset) => asset.id == entry.key)
                .hash,
            entry.value,
            reason: 'A size retry must retain a completed exact SHA.',
          );
        }
        debugPrint(
          'PHOTO_SIZE_ROUND_$sizeRounds '
          '${_sizeRoundDiagnostics(scanner, movieIds)}',
        );
      }
      stages['sizeRounds'] = sizeRounds;
      _expectMovies(scanner, movieIds, expectedBytes);
      _expectExactPair(scanner, duplicateIds, differentIds);
      for (final entry in originalHash.entries) {
        expect(
          scanner.scanResult.allAssets
              .firstWhere((a) => a.id == entry.key)
              .hash,
          entry.value,
          reason: 'Size-only checks must preserve unchanged complete hashes.',
        );
      }
      stages['largeFileCount'] = scanner.scanResult.largeFiles.length;
      stages['knownSizeCount'] = scanner.knownSizeAssetCount;
      stages['largestMovieBytes'] = movieIds
          .map((id) => expectedBytes[id] as int)
          .reduce((a, b) => a > b ? a : b);
      await tester.pump(const Duration(milliseconds: 600));
      await _revealAsset(tester, movieIds.last);
      _expectActiveCategoryVisible(tester, labels.scanCategoryLarge);

      // Large libraries retain pending previews after their bounded first pass.
      // Continue visual analysis from the Home action, then reopen the same
      // cleanup category. Its compact toolbar stays focused on capacity checks.
      var previewContinuationChecked = false;
      if (scanner.pendingAnalysisCount > 0) {
        final knownBeforePreview = scanner.knownSizeAssetCount;
        final attemptedBeforePreview = scanner.attemptedAnalysisCount;
        watch.reset();
        await _showHome(tester, scanner, subscription);
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('home-scan-continue')),
        );
        // Leave Home right away: once previews finish it would start its own
        // original check and race the assertions below.
        await _showTool(tester, scanner, subscription, null);
        await _waitUntil(
          tester,
          () => scanner.isScanning,
          'preview resume start',
        );
        await _waitUntil(
          tester,
          () =>
              scanner.attemptedAnalysisCount > attemptedBeforePreview ||
              !scanner.isScanning,
          'preview resume progress',
        );
        // The purpose here is to verify preservation across a resumed round,
        // not to exhaust every remaining cloud-only photo in the fixture.
        if (scanner.isContinuousScanning) {
          await scanner.pauseContinuousScan();
        }
        await _waitUntil(tester, () => !scanner.isScanning, 'preview pause');
        _expectMovies(scanner, movieIds, expectedBytes);
        _expectExactPair(scanner, duplicateIds, differentIds);
        expect(
          scanner.knownSizeAssetCount,
          greaterThanOrEqualTo(knownBeforePreview),
        );
        stages['previewResumeMs'] = watch.elapsedMilliseconds;
        stages['previewResumeAnalyzedCount'] = scanner.analyzedAssetCount;
        stages['previewResumePendingCount'] = scanner.pendingAnalysisCount;
        stages['previewResumeKnownSizeCount'] = scanner.knownSizeAssetCount;
        previewContinuationChecked = true;
        await _showTool(tester, scanner, subscription, 'largeFiles');
        await tester.pump(const Duration(milliseconds: 600));
        await _revealAsset(tester, movieIds.last);
        _expectActiveCategoryVisible(tester, labels.scanCategoryLarge);
      }
      await _capture(binding, 'photos-$workload-large');

      // Free cleanup review must play the actual local original, independently
      // of compression or StoreKit. Exercise native playback and seek controls.
      final movie = find.byKey(ValueKey('select-${movieIds.last}'));
      await _tapVisible(
        tester,
        find.descendant(
          of: movie,
          matching: find.byTooltip(labels.videoPlayOriginal),
        ),
      );
      await _waitUntil(
        tester,
        () => find.byType(VideoPlaybackControls).evaluate().isNotEmpty,
        'local original movie preview',
      );
      final controls = tester.widget<VideoPlaybackControls>(
        find.byType(VideoPlaybackControls),
      );
      expect(controls.controller.value.duration.inSeconds, greaterThan(0));
      await tester.tap(
        find.descendant(
          of: find.byType(VideoPlaybackControls),
          matching: find.byTooltip(labels.videoPlayOriginal),
        ),
      );
      await tester.pump();
      await _waitUntil(
        tester,
        () =>
            controls.controller.value.isPlaying &&
            controls.controller.value.position.inMilliseconds > 0,
        'native original playback',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(VideoPlaybackControls),
          matching: find.byTooltip(labels.videoPauseOriginal),
        ),
      );
      await tester.pump();
      await _waitUntil(
        tester,
        () => !controls.controller.value.isPlaying,
        'native original pause',
      );
      final durationMs = controls.controller.value.duration.inMilliseconds;
      final pausedMs = controls.controller.value.position.inMilliseconds;
      final seekFraction = pausedMs < durationMs / 2 ? 0.8 : 0.2;
      final slider = find.byType(Slider);
      final sliderRect = tester.getRect(slider);
      // Match the Material slider's 24px horizontal track inset and use a
      // real hit-tested gesture, rather than invoking its callback directly.
      final targetMs = durationMs * seekFraction;
      await tester.tapAt(
        Offset(
          sliderRect.left + 24 + (sliderRect.width - 48) * seekFraction,
          sliderRect.center.dy,
        ),
      );
      await tester.pump();
      await _waitUntil(
        tester,
        () =>
            (controls.controller.value.position.inMilliseconds - targetMs)
                .abs() <=
            500,
        'native original seek',
      );
      expect(controls.controller.value.hasError, isFalse);
      stages['originalVideoDurationSeconds'] =
          controls.controller.value.duration.inSeconds;
      await _tapVisible(tester, find.text(labels.scanBackToCompare));

      // The same verified library through the real v2 app shell: Home's
      // category wall -> first-visit intro -> review screens a user reaches.
      await _mount(tester, scanner, subscription, const MainTabView());
      await tester.pump(const Duration(milliseconds: 600));
      var homeContinueChecked = false;
      final checkPaused = find.text(labels.v2CheckPaused);
      if (checkPaused.evaluate().isNotEmpty) {
        final verifiedBefore = scanner.verifiedHashAssetCount;
        final knownBefore = scanner.knownSizeAssetCount;
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('home-scan-continue')),
        );
        await _waitUntil(
          tester,
          () => scanner.isScanning,
          'home originals continue start',
        );
        await _waitUntil(
          tester,
          () => !scanner.isScanning,
          'home originals continue end',
        );
        expect(
          scanner.verifiedHashAssetCount,
          greaterThanOrEqualTo(verifiedBefore),
        );
        expect(scanner.knownSizeAssetCount, greaterThanOrEqualTo(knownBefore));
        homeContinueChecked = true;
      }
      if (scanner.isScanning) {
        // Home may start its own originals round; it must not race the
        // navigation checks below.
        scanner.cancelScan();
        await _waitUntil(tester, () => !scanner.isScanning, 'home round stop');
      }
      stages['v2HomeOriginalsContinueChecked'] = homeContinueChecked;

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('home-category-duplicates')),
      );
      await _tapVisible(tester, find.byKey(const ValueKey('intro-lets-go')));
      await _waitUntil(
        tester,
        () => find.byType(GroupReviewView).evaluate().isNotEmpty,
        'v2 duplicates review',
      );
      for (final id in duplicateIds) {
        await _waitUntil(
          tester,
          () => find
              .byKey(ValueKey('group-tile-$id'), skipOffstage: false)
              .evaluate()
              .isNotEmpty,
          'v2 duplicate tile $id',
        );
      }
      await _capture(binding, 'photos-$workload-v2-duplicates');
      Navigator.of(tester.element(find.byType(GroupReviewView))).pop();
      await tester.pump(const Duration(milliseconds: 600));

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('home-category-largeFiles')),
      );
      await _tapVisible(tester, find.byKey(const ValueKey('intro-lets-go')));
      await _waitUntil(
        tester,
        () => find.byType(CategoryGridView).evaluate().isNotEmpty,
        'v2 large files grid',
      );
      for (final id in movieIds) {
        await _waitUntil(
          tester,
          () => find
              .byKey(ValueKey('grid-tile-$id'), skipOffstage: false)
              .evaluate()
              .isNotEmpty,
          'v2 large file tile $id',
        );
      }
      await _capture(binding, 'photos-$workload-v2-large');

      // A separate fresh scanner really cancels its first native-resource pass;
      // then resume must recover both real videos without losing fair progress.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      final interrupted = PhotoScannerService();
      addTearDown(interrupted.dispose);
      final cancelled = Completer<void>();
      void cancelAfterFirstAttempt() {
        if (interrupted.attemptedResourceCount > 0 && !cancelled.isCompleted) {
          cancelled.complete();
          scheduleMicrotask(interrupted.cancelScan);
        }
      }

      interrupted.addListener(cancelAfterFirstAttempt);
      watch.reset();
      await interrupted.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      interrupted.removeListener(cancelAfterFirstAttempt);
      expect(cancelled.isCompleted, isTrue);
      expect(interrupted.wasCancelled, isTrue);
      expect(interrupted.attemptedResourceCount, greaterThanOrEqualTo(1));
      expect(interrupted.scannedAssetCount, greaterThanOrEqualTo(actualCount));
      stages['cancelledFirstPassMs'] = watch.elapsedMilliseconds;
      watch.reset();
      var resumeRounds = 0;
      while (!_hasMovies(interrupted, movieIds) && resumeRounds < 3) {
        await interrupted.verifyOriginals(
          target: OriginalVerificationTarget.fileSizes,
        );
        resumeRounds++;
      }
      _expectMovies(interrupted, movieIds, expectedBytes);
      stages['sizeResumeRounds'] = resumeRounds;
      stages['sizeResumeMs'] = watch.elapsedMilliseconds;
      stages['resumedKnownSizeCount'] = interrupted.knownSizeAssetCount;
      stages['resumedIndexedCount'] = interrupted.scannedAssetCount;

      final report = <String, Object?>{
        'schemaVersion': 1,
        'workloadPhotos': workload,
        'workloadShortVideos': shortVideoCount,
        'workloadLargeVideos': 2,
        'actualFixtureCount': actualCount,
        'usesRealPhotosLibrary': true,
        'usesRealFlutterScannerAndNativeBridge': true,
        // v2 Home starts and resumes the scan; the review tool is mounted
        // directly because v2 Home no longer links to it.
        'usesHomeScanAndToolNavigation': false,
        'usesV2HomeScanStartAndResume': true,
        'v2NavigationReachesVerifiedResults': true,
        'usesMockChannelsOrFakeSizes': false,
        'exactDuplicatePairDetected': true,
        'differentPhotosNotGroupedWithExactPair': true,
        'largeMovieAbove64MiBDetectedWithExactBytes': true,
        'categoryEntryAutomaticallyVerified': true,
        'sizeOnlyPreservedHashes': true,
        'previewContinuationChecked': previewContinuationChecked,
        'previewContinuationPreservedOriginalResults':
            previewContinuationChecked,
        'cancelAndResumeRecoveredMovies': true,
        'realOriginalVideoPlaybackAndSeekChecked': true,
        'screenshotFiles': [
          'photos-$workload-exact.png',
          'photos-$workload-large.png',
          'photos-$workload-v2-duplicates.png',
          'photos-$workload-v2-large.png',
        ],
        'stages': stages,
      };
      await File(
        '${documents.path}/cleanup-library-test-$workload.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      binding.reportData = {'libraryScan': report};
      // The workflow also exports the actual files from the simulator container.
      debugPrint('CLEANUP_REAL_LIBRARY_RESULT ${jsonEncode(report)}');
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

Future<void> _showHome(
  WidgetTester tester,
  PhotoScannerService scanner,
  SubscriptionManager subscription,
) => _mount(tester, scanner, subscription, const HomeView());

/// Mounts the review tool for [category] (or an empty page when null) in
/// place of Home, so Home's automatic original check cannot race the rounds
/// this test starts itself.
Future<void> _showTool(
  WidgetTester tester,
  PhotoScannerService scanner,
  SubscriptionManager subscription,
  String? category,
) async {
  await _mount(
    tester,
    scanner,
    subscription,
    category == null
        ? const Scaffold(body: SizedBox.shrink())
        : SmartCleanView(key: ValueKey(category), initialCategory: category),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _mount(
  WidgetTester tester,
  PhotoScannerService scanner,
  SubscriptionManager subscription,
  Widget home,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
      ],
      child: MaterialApp(
        locale: const Locale('zh', 'TW'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: LocaleController.supportedLocales,
        localeListResolutionCallback: LocaleController.resolve,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _revealAsset(WidgetTester tester, String id) async {
  final target = find.byKey(ValueKey('select-$id'));
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
  expect(vertical, findsWidgets);
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: vertical.first,
    maxScrolls: 30,
  );
  await tester.pump(const Duration(milliseconds: 400));
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'The actual result must be visible in the viewport.',
  );
}

void _expectActiveCategoryVisible(WidgetTester tester, String label) {
  final chip = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.selected == true &&
        widget.properties.button == true,
  );
  expect(chip, findsOneWidget);
  expect(find.descendant(of: chip, matching: find.text(label)), findsOneWidget);
  final bounds = tester.getRect(chip);
  final viewportWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(bounds.left, greaterThanOrEqualTo(0));
  expect(bounds.right, lessThanOrEqualTo(viewportWidth));
  expect(chip.hitTestable(), findsOneWidget);
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() ready,
  String stage,
) async {
  final watch = Stopwatch()..start();
  while (!ready() && watch.elapsed < const Duration(seconds: 110)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue, reason: '$stage did not finish before its deadline.');
}

void _expectExactPair(
  PhotoScannerService scanner,
  List<String> duplicates,
  List<String> different,
) {
  final matches = scanner.scanResult.duplicateGroups.where(
    (g) => g.assets.map((a) => a.id).toSet().containsAll(duplicates),
  );
  expect(
    matches,
    hasLength(1),
    reason: 'The two identical originals are missing.',
  );
  final group = matches.single;
  expect(group.assets.map((a) => a.id).toSet(), equals(duplicates.toSet()));
  expect(
    scanner.scanResult.duplicateGroups
        .expand((g) => g.assets)
        .map((a) => a.id)
        .toSet()
        .intersection(different.toSet()),
    isEmpty,
  );
  expect(
    group.assets.every((a) => a.sizeKnown && a.hash == group.hash),
    isTrue,
  );
  expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(group.hash), isTrue);
}

bool _hasExactPair(PhotoScannerService scanner, List<String> ids) => scanner
    .scanResult
    .duplicateGroups
    .any((g) => g.assets.map((a) => a.id).toSet().containsAll(ids));

bool _hasMovies(PhotoScannerService scanner, List<String> ids) =>
    scanner.scanResult.largeFiles.map((a) => a.id).toSet().containsAll(ids);

Map<String, Object?> _sizeRoundDiagnostics(
  PhotoScannerService scanner,
  List<String> movieIds,
) {
  final byId = {
    for (final asset in scanner.scanResult.allAssets) asset.id: asset,
  };
  return {
    'roundTotal': scanner.originalRoundTotal,
    'roundProcessed': scanner.originalRoundProcessed,
    'knownSizes': scanner.knownSizeAssetCount,
    'verifiedHashes': scanner.verifiedHashAssetCount,
    'pendingSizes': scanner.pendingSizeAssetCount,
    'lastError': scanner.lastError,
    'movies': [
      for (var i = 0; i < movieIds.length; i++)
        if (byId[movieIds[i]] case final asset?)
          {
            'fixture': i + 1,
            'sizeKnown': asset.sizeKnown,
            'size': asset.size,
            'attempted': asset.resourceAnalysisAttempted,
            'pendingReason': asset.resourcePendingReason,
          }
        else
          {'fixture': i + 1, 'indexed': false},
    ],
  };
}

Map<String, int> _metadataDrift(
  Map<String, PhotoAsset> previous,
  List<PhotoAsset> current,
) {
  final changes = <String, int>{
    'previousKnownSizes': previous.values.where((a) => a.sizeKnown).length,
    'currentKnownSizes': current.where((a) => a.sizeKnown).length,
    'previousHashes': previous.values.where((a) => a.hash != null).length,
    'currentHashes': current.where((a) => a.hash != null).length,
    'missingIds':
        previous.length -
        current.where((a) => previous.containsKey(a.id)).length,
  };
  void count(String field) =>
      changes.update(field, (value) => value + 1, ifAbsent: () => 1);
  for (final asset in current) {
    final old = previous[asset.id];
    if (old == null) {
      count('newIds');
      continue;
    }
    if (old.modifiedDate != asset.modifiedDate) count('modifiedDate');
    if (old.createDate != asset.createDate) count('createDate');
    if (old.width != asset.width || old.height != asset.height) {
      count('dimensions');
    }
    if (old.type != asset.type) count('type');
    if (old.durationSeconds != asset.durationSeconds) count('duration');
    if (old.isScreenshot != asset.isScreenshot) count('isScreenshot');
    if (old.title != asset.title) count('title');
  }
  return changes;
}

void _expectMovies(
  PhotoScannerService scanner,
  List<String> movies,
  Map<String, dynamic> sizes,
) {
  expect(
    _hasMovies(scanner, movies),
    isTrue,
    reason:
        'Fixture movie capacities remain pending: '
        '${_sizeRoundDiagnostics(scanner, movies)}',
  );
  for (final id in movies) {
    final asset = scanner.scanResult.largeFiles.firstWhere((a) => a.id == id);
    expect(asset.sizeKnown, isTrue);
    expect(asset.size, sizes[id]);
    expect(asset.size, greaterThan(5 * 1024 * 1024));
    expect(asset.durationSeconds, greaterThan(0));
  }
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  expect(bytes.length, greaterThan(1000));
  final documents = await getApplicationDocumentsDirectory();
  await File('${documents.path}/$name.png').writeAsBytes(bytes);
}
