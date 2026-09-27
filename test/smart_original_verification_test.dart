import 'dart:convert';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  const resources = MethodChannel('cleanup/photo_resources');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final png = img.encodePng(img.Image(width: 32, height: 32));
  final digest = sha256
      .convert(utf8.encode('identical-original-fixture'))
      .toString();
  late PhotoScannerService scanner;
  late SubscriptionManager subscriptions;
  late List<Map<String, Object>> library;
  late List<Map> inspections;

  Map<String, Object> asset(String id, {int type = 1}) => {
    'id': id,
    'type': type,
    'width': 2000,
    'height': 1500,
    'createDt': 1700000000,
    'modifiedDt': 1700000000,
    'title': '$id.jpg',
  };

  setUp(() {
    scanner = PhotoScannerService(supportsNativeResources: true);
    subscriptions = SubscriptionManager();
    library = [asset('original-a'), asset('original-b')];
    inspections = [];
    messenger.setMockMethodCallHandler(photos, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          return PermissionState.authorized.index;
        case 'getAssetPathList':
          return {
            'data': [
              {
                'id': 'all',
                'name': 'All',
                'isAll': true,
                'assetCount': library.length,
              },
            ],
          };
        case 'getAssetCountFromPath':
          return library.length;
        case 'getAssetListRange':
          final args = call.arguments as Map;
          return {
            'data': library.sublist(args['start'] as int, args['end'] as int),
          };
        case 'fetchEntityProperties':
          final id = (call.arguments as Map)['id'];
          return library.firstWhere((item) => item['id'] == id);
        case 'getThumb':
          return png;
        default:
          throw StateError('Unexpected Photos request ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(resources, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'cancelInspections') return null;
      if (call.method == 'inspectPreviews') {
        return {
          'assets': [
            for (final id in args['assetIds'] as List)
              {'assetId': id, 'status': 'local', 'thumbnail': png},
          ],
        };
      }
      expect(call.method, 'inspectAsset');
      inspections.add(Map.of(args));
      final includeHash = args['includeHash'] == true;
      return {
        'complete': true,
        'sizeComplete': true,
        'sizeKnown': true,
        'size': 12 * 1024 * 1024,
        'hashComplete': includeHash,
        if (includeHash) 'hash': digest,
      };
    });
  });
  tearDown(() {
    scanner.dispose();
    subscriptions.dispose();
    messenger.setMockMethodCallHandler(photos, null);
    messenger.setMockMethodCallHandler(resources, null);
  });

  Future<void> mount(WidgetTester tester, String category) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscriptions,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SmartCleanView(initialCategory: category),
        ),
      ),
    );
  }

  Future<void> finish(WidgetTester tester, bool Function() ready) async {
    for (var frame = 0; frame < 100 && !ready(); frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(
      ready(),
      isTrue,
      reason:
          'Real scanner result: scanning=${scanner.isScanning}, phase=${scanner.currentPhase}, indexed=${scanner.scannedAssetCount}, known=${scanner.knownSizeAssetCount}, hash=${scanner.verifiedHashAssetCount}, calls=${inspections.length}, error=${scanner.lastError}',
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'initial exact category starts real original inspections and renders SHA group',
    (tester) async {
      await mount(tester, 'duplicates');
      await finish(
        tester,
        () =>
            !scanner.isScanning &&
            scanner.scanResult.duplicateGroups.isNotEmpty,
      );
      expect(inspections, hasLength(2));
      expect(inspections.every((args) => args['includeHash'] == true), isTrue);
      expect(scanner.verifiedHashAssetCount, 2);
      expect(find.text('Exact duplicates: 2 photos'), findsOneWidget);
      expect(
        find.byKey(ValueKey('keep-suggested-duplicate:$digest')),
        findsOneWidget,
      );
      expect(find.textContaining('Selected items:'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'entering large category after preview sends size-only work and renders video',
    (tester) async {
      library = [asset('original-a'), asset('local-video', type: 2)];
      await tester.runAsync(scanner.startFullScan);
      expect(
        inspections,
        isEmpty,
        reason: 'Ordinary preview scanning still does not hash original files.',
      );
      await mount(tester, 'photos');
      await tester.pumpAndSettle();
      expect(inspections, isEmpty);
      final strings = AppLocalizations.of(
        tester.element(find.byType(SmartCleanView)),
      );
      final category = find.text(strings.scanCategoryLarge).first;
      await tester.ensureVisible(category);
      await tester.pump();
      await tester.tap(category);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.scanResult.largeFiles.isNotEmpty,
      );
      expect(inspections, isNotEmpty);
      expect(inspections.every((args) => args['includeHash'] == false), isTrue);
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(
        scanner.scanResult.largeFiles.map((a) => a.id),
        contains('local-video'),
      );
      expect(find.text('12.0 MB'), findsWidgets);
      expect(find.byKey(const ValueKey('select-local-video')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
