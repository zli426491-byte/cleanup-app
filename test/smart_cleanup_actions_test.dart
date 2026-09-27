import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

final _png = img.encodePng(img.Image(width: 8, height: 8));
PhotoAsset _asset(String id, {bool video = false}) => PhotoAsset(
  id: id,
  title: id,
  width: 100,
  height: 100,
  size: 100,
  sizeKnown: true,
  analysisPending: false,
  thumbnail: _png,
  createDate: DateTime(2026),
  type: video ? AssetType.video : AssetType.image,
);

class _Scanner extends PhotoScannerService {
  _Scanner({
    this.pendingHash = 0,
    this.pendingSize = 0,
    bool groups = false,
    bool screenshots = true,
  }) {
    final photos = List.generate(4, (index) => _asset('action-$index'));
    final video = _asset('action-video', video: true);
    result = ScanResult(
      allAssets: [...photos, video],
      duplicateGroups: groups
          ? [
              DuplicateGroup(
                hash: 'exact',
                assets: photos.take(3).toList(),
                bestAssetId: photos.first.id,
              ),
            ]
          : [],
      similarGroups: groups
          ? [SimilarGroup(assets: photos.skip(2).toList(), hammingDistance: 3)]
          : [],
      screenshots: screenshots ? [photos.last] : [],
      largeFiles: [video],
      videos: [video],
      blurryPhotos: [],
      darkPhotos: [],
      overexposedPhotos: [],
      totalSavingsEstimate: 0,
    );
  }
  late final ScanResult result;
  final int pendingHash;
  final int pendingSize;
  int verifyCalls = 0;
  bool checking = false;
  @override
  ScanResult get scanResult => result;
  @override
  bool get isScanning => checking;
  @override
  bool get isVerifyingOriginals => checking;
  @override
  int get scannedAssetCount => 5;
  @override
  int get totalPhotoCount => 4;
  @override
  int get pendingHashAssetCount => pendingHash;
  @override
  int get verifiedHashAssetCount => 4 - pendingHash;
  @override
  int get pendingSizeAssetCount => pendingSize;
  @override
  int get knownSizeAssetCount => 5 - pendingSize;
  @override
  int get pendingResourceCount => pendingHash + pendingSize;
  @override
  int get pendingAnalysisCount => 0;
  @override
  String? get scanNotice => '已暫停，已讀取與分析的結果已保留，可繼續掃描。';
  @override
  Future<void> verifyOriginals() async {
    verifyCalls++;
    checking = true;
    notifyListeners();
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Scanner scanner,
  String category, {
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  final subscription = SubscriptionManager();
  addTearDown(scanner.dispose);
  addTearDown(subscription.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SmartCleanView(initialCategory: category),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

bool _selected(WidgetTester tester, String id) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.checked != null &&
        widget.properties.label?.contains(' · $id · ') == true,
  );
  return tester.widget<Semantics>(finder).properties.checked ?? false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'fetchEntityProperties') {
            return {
              'id': (call.arguments as Map)['id'],
              'type': 1,
              'width': 100,
              'height': 100,
            };
          }
          if (call.method == 'getThumb') return _png;
          return null;
        }),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets(
    'text swipe entry uses only current category and empty never falls back',
    (tester) async {
      await _mount(tester, _Scanner(), 'screenshots');
      expect(find.byTooltip('Swipe cleanup'), findsNothing);
      await _tapKey(tester, 'start-category-swipe');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwipeCleanView>(find.byType(SwipeCleanView))
            .assets
            .map((asset) => asset.id),
        ['action-3'],
      );
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, _Scanner(screenshots: false), 'screenshots');
      expect(find.byKey(const ValueKey('start-category-swipe')), findsNothing);
      expect(find.byType(SwipeCleanView), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'exact and size cards use independent counters and verify explicitly',
    (tester) async {
      final scanner = _Scanner(pendingHash: 3, pendingSize: 1);
      await _mount(tester, scanner, 'duplicates');
      expect(
        find.byKey(const ValueKey('original-verification-card')),
        findsOneWidget,
      );
      expect(find.text('Checked 1 / 4 items'), findsOneWidget);
      expect(find.text('3 items to check'), findsOneWidget);
      expect(find.byKey(const ValueKey('start-category-swipe')), findsNothing);
      expect(scanner.verifyCalls, 0);
      await _tapKey(tester, 'verify-originals-cta');
      expect(scanner.verifyCalls, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('verify-originals-cta')),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      await _mount(
        tester,
        _Scanner(pendingHash: 3, pendingSize: 1),
        'largeFiles',
      );
      expect(find.text('Checked 4 / 5 items'), findsOneWidget);
      expect(find.text('1 items to check'), findsOneWidget);
      await tester.tap(find.text('Organize photos first'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('select-current-category')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'scan details collapsed by default and reveal full notice on demand',
    (tester) async {
      await _mount(tester, _Scanner(), 'photos');
      final notice = AppLocalizations.of(
        tester.element(find.byType(SmartCleanView)),
      ).serviceScanPaused;
      expect(find.text(notice), findsNothing);
      await tester.tap(find.byKey(const ValueKey('scan-details-0')));
      await tester.pumpAndSettle();
      expect(find.text(notice), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'manual bulk actions only select current category and can clear or undo',
    (tester) async {
      await _mount(tester, _Scanner(), 'screenshots');
      await _tapKey(tester, 'select-current-category');
      expect(find.text('Selected items: 1'), findsOneWidget);
      await tester.tap(find.text('Clear selection'));
      await tester.pump();
      expect(find.text('Selected items: 1'), findsNothing);
      await tester.tap(find.text('Undo last choice'));
      await tester.pump();
      expect(find.text('Selected items: 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, _Scanner(), 'photos');
      await _tapKey(tester, 'select-current-category');
      expect(find.text('Selected items: 4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'group action is manual and keeps suggested or explicitly chosen photo',
    (tester) async {
      await _mount(tester, _Scanner(groups: true), 'duplicates');
      expect(
        find.byKey(const ValueKey('select-current-category')),
        findsNothing,
      );
      expect(find.textContaining('Selected items:'), findsNothing);
      await _tapKey(tester, 'keep-suggested-duplicate:exact');
      await tester.ensureVisible(find.byKey(const ValueKey('select-action-0')));
      await tester.pump();
      expect(_selected(tester, 'action-0'), isFalse);
      expect(_selected(tester, 'action-1'), isTrue);
      expect(_selected(tester, 'action-2'), isTrue);
      expect(find.text('Selected items: 2'), findsOneWidget);
      await _tapKey(tester, 'keep-group-action-1');
      expect(_selected(tester, 'action-0'), isTrue);
      expect(_selected(tester, 'action-1'), isFalse);
      expect(_selected(tester, 'action-2'), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('group without quality recommendation never guesses a keeper', (
    tester,
  ) async {
    await _mount(tester, _Scanner(groups: true), 'similar');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith(
              'keep-suggested-',
            ),
      ),
      findsNothing,
    );
    expect(find.textContaining('Selected items:'), findsNothing);
    await _tapKey(tester, 'keep-group-action-2');
    expect(_selected(tester, 'action-2'), isFalse);
    expect(_selected(tester, 'action-3'), isTrue);
    expect(find.text('Selected items: 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(320, 568), const Size(1366, 1024)]) {
    testWidgets('bulk and verification cards support $size large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        _Scanner(groups: true, pendingHash: 2),
        'duplicates',
        textScale: 2,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('keep-group-action-0')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'initial large-files chip is visible and identifies selected category',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, _Scanner(), 'largeFiles');
      final chip = find.text('Large files').first;
      expect(tester.getRect(chip).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(chip).right, lessThanOrEqualTo(320));
      final semantics = find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.selected == true &&
              widget.properties.button == true,
        ),
      );
      expect(semantics, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in [const Size(320, 568), const Size(1366, 1024)]) {
      testWidgets('$locale $size enriched cleanup supports 200 percent text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          _Scanner(groups: true),
          'similar',
          textScale: 2,
          locale: locale,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('keep-group-action-2')),
          180,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('keep-group-action-2')));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await _mount(
          tester,
          _Scanner(pendingSize: 1),
          'largeFiles',
          textScale: 2,
          locale: locale,
        );
        expect(
          find.byKey(const ValueKey('original-verification-card')),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('select-current-category')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('select-current-category')));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
    'keeper action identifies the photo and supports keyboard activation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _mount(tester, _Scanner(groups: true), 'similar');
      final button = find.byKey(const ValueKey('keep-group-action-2'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      final label = find.descendant(of: button, matching: find.byType(Text));
      expect(tester.widget<Text>(label).semanticsLabel, contains('action-2'));
      Focus.of(tester.element(label)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_selected(tester, 'action-2'), isFalse);
      expect(_selected(tester, 'action-3'), isTrue);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  testWidgets('browse photos reveals the programmatically selected chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, _Scanner(pendingSize: 1), 'largeFiles');
    final label = AppLocalizations.of(
      tester.element(find.byType(SmartCleanView)),
    ).scanBrowsePhotos;
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    final chip = find.text('Photos').first;
    expect(tester.getRect(chip).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(chip).right, lessThanOrEqualTo(320));
    expect(
      find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.selected == true &&
              widget.properties.button == true,
        ),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'videos and large files use batch selection without photo-only swipe wording',
    (tester) async {
      for (final category in ['videos', 'largeFiles']) {
        await _mount(tester, _Scanner(), category);
        expect(
          find.byKey(const ValueKey('start-category-swipe')),
          findsNothing,
        );
        await _tapKey(tester, 'select-current-category');
        expect(find.text('Selected items: 1'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
