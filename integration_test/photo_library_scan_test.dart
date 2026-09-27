import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Actual Photos/MethodChannel/Flutter integration on the disposable CI
/// simulator. No mock channels, fabricated sizes, deletion or StoreKit calls.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real large Photos library finds exact copies and large movies',
    (tester) async {
      const encoded = String.fromEnvironment('CLEANUP_FIXTURE_MANIFEST_B64');
      expect(
        Platform.isIOS,
        isTrue,
        reason: 'Requires the isolated iOS simulator.',
      );
      expect(
        encoded,
        isNotEmpty,
        reason: 'A native verified seed is mandatory.',
      );
      final manifest = jsonDecode(utf8.decode(base64Decode(encoded))) as Map;
      final workload = manifest['workloadCount'] as int;
      final actualCount = manifest['actualFixtureCount'] as int;
      expect(workload, anyOf(1000, 10000));
      expect(actualCount, greaterThanOrEqualTo(workload));
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
      await _tapVisible(tester, find.text(labels.homeScanAll));
      await _waitUntil(
        tester,
        () => scanner.isScanning || scanner.scannedAssetCount > 0,
        'home scan start',
      );
      await _waitUntil(tester, () => !scanner.isScanning, 'home scan end');
      stages['initialPreviewMs'] = watch.elapsedMilliseconds;
      expect(scanner.scannedAssetCount, greaterThanOrEqualTo(actualCount));
      expect(scanner.nativeOriginalAnalysisAvailable, isTrue);
      final indexed = scanner.scanResult.allAssets.map((a) => a.id).toSet();
      expect(
        indexed,
        containsAll([...duplicateIds, ...differentIds, ...movieIds]),
      );
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.knownSizeAssetCount, 0);
      stages['indexedCount'] = scanner.scannedAssetCount;
      stages['previewAnalyzedCount'] = scanner.analyzedAssetCount;
      stages['previewPendingCount'] = scanner.pendingAnalysisCount;

      // Ordinary category entry must produce data without a second button tap.
      watch.reset();
      await _tapVisible(tester, find.text(labels.homeExactDuplicates));
      expect(find.byType(SmartCleanView), findsOneWidget);
      await _waitUntil(
        tester,
        () =>
            scanner.isScanning || scanner.scanResult.duplicateGroups.isNotEmpty,
        'automatic exact start',
      );
      await _waitUntil(
        tester,
        () => !scanner.isScanning,
        'automatic exact end',
      );
      stages['automaticExactMs'] = watch.elapsedMilliseconds;
      _expectExactPair(scanner, duplicateIds, differentIds);
      stages['exactGroupCount'] = scanner.scanResult.duplicateGroups.length;
      stages['exactVerifiedPhotoCount'] = scanner.verifiedHashAssetCount;
      final originalHash = {
        for (final id in duplicateIds)
          id: scanner.scanResult.allAssets.firstWhere((a) => a.id == id).hash,
      };
      await tester.pump(const Duration(milliseconds: 600));
      await _revealAsset(tester, duplicateIds.first);
      await _capture(binding, 'photos-$workload-exact');

      watch.reset();
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 400));
      await _tapVisible(tester, find.text(labels.homeLargeFiles));
      expect(find.byType(SmartCleanView), findsOneWidget);
      await _waitUntil(
        tester,
        () => scanner.isScanning || _hasMovies(scanner, movieIds),
        'automatic size start',
      );
      await _waitUntil(tester, () => !scanner.isScanning, 'automatic size end');
      stages['automaticLargeMs'] = watch.elapsedMilliseconds;
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
      await _capture(binding, 'photos-$workload-large');

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
        'actualFixtureCount': actualCount,
        'usesRealPhotosLibrary': true,
        'usesRealFlutterScannerAndNativeBridge': true,
        'usesHomeScanAndToolNavigation': true,
        'usesMockChannelsOrFakeSizes': false,
        'exactDuplicatePairDetected': true,
        'differentPhotosNotGroupedWithExactPair': true,
        'largeMovieAbove64MiBDetectedWithExactBytes': true,
        'categoryEntryAutomaticallyVerified': true,
        'sizeOnlyPreservedHashes': true,
        'cancelAndResumeRecoveredMovies': true,
        'screenshotFiles': [
          'photos-$workload-exact.png',
          'photos-$workload-large.png',
        ],
        'stages': stages,
      };
      final documents = await getApplicationDocumentsDirectory();
      await File(
        '${documents.path}/cleanup-library-test-$workload.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      binding.reportData = {'libraryScan': report};
      // The workflow also exports the actual files from the simulator container.
      debugPrint('CLEANUP_REAL_LIBRARY_RESULT ${jsonEncode(report)}');
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<void> _showHome(
  WidgetTester tester,
  PhotoScannerService scanner,
  SubscriptionManager subscription,
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
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeView(),
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

bool _hasMovies(PhotoScannerService scanner, List<String> ids) =>
    scanner.scanResult.largeFiles.map((a) => a.id).toSet().containsAll(ids);

void _expectMovies(
  PhotoScannerService scanner,
  List<String> movies,
  Map<String, dynamic> sizes,
) {
  expect(_hasMovies(scanner, movies), isTrue);
  for (final id in movies) {
    final asset = scanner.scanResult.largeFiles.firstWhere((a) => a.id == id);
    expect(asset.sizeKnown, isTrue);
    expect(asset.size, sizes[id]);
    expect(asset.size, greaterThan(5 * 1024 * 1024));
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
