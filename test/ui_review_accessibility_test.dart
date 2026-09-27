import 'dart:async';
import 'dart:ui' show CheckedState, Tristate;

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/asset_preview.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

final _pixel = Uint8List.fromList(
  img.encodePng(
    img.Image(width: 8, height: 24)
      ..setPixelRgb(0, 0, 255, 0, 0)
      ..setPixelRgb(7, 23, 0, 0, 255),
  ),
);
PhotoAsset _photo(String id, {Uint8List? thumbnail}) => PhotoAsset(
  id: id,
  width: 600,
  height: 1800,
  size: 0,
  createDate: DateTime(2026, 9, 20),
  type: AssetType.image,
  thumbnail: thumbnail,
);

class _Scanner extends PhotoScannerService {
  _Scanner({this.indexComplete = true});
  final bool indexComplete;
  late final result = ScanResult(
    allAssets: [
      _photo('review-first', thumbnail: _pixel),
      if (indexComplete) _photo('review-second', thumbnail: _pixel),
    ],
    duplicateGroups: [],
    similarGroups: [],
    screenshots: [],
    largeFiles: [],
    videos: [],
    blurryPhotos: [],
    darkPhotos: [],
    overexposedPhotos: [],
    totalSavingsEstimate: 0,
  );
  @override
  ScanResult get scanResult => result;
  @override
  bool get hasCompletedScan => indexComplete;
  @override
  int get scannedAssetCount => result.allAssets.length;
  @override
  int? get availableAssetCount => 2;
  @override
  int get pendingAnalysisCount => 0;
  @override
  int get pendingResourceCount => 0;
  @override
  String? get scanNotice => null;
}

class _EmptyScanner extends _Scanner {
  @override
  ScanResult get scanResult => ScanResult.empty;
  @override
  int get scannedAssetCount => 0;
  @override
  int? get availableAssetCount => 0;
}

class _DeletingScanner extends _Scanner {
  final deletion = Completer<Set<String>>();
  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) =>
      deletion.future;
}

class _Pro extends SubscriptionManager {
  @override
  bool get isPro => true;
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);
Future<void> _mount(
  WidgetTester tester,
  Widget view, {
  _Scanner? scanner,
  SubscriptionManager? subscriptions,
}) async {
  final state = scanner ?? _Scanner();
  final subscription = subscriptions ?? SubscriptionManager();
  addTearDown(state.dispose);
  addTearDown(subscription.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: state),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
      ],
      child: _app(view),
    ),
  );
  await tester.pumpAndSettle();
  if (view is SmartCleanView) {
    final context = tester.element(find.byType(SmartCleanView));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context, onError: (_, _) {});
      }
    });
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<Map<Object?, Object?>> requests;
  Completer<Uint8List?>? pending;
  setUp(() {
    requests = [];
    pending = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<Object?, Object?>.from(call.arguments as Map);
      if (call.method == 'fetchEntityProperties') {
        return {'id': args['id'], 'type': 1, 'width': 600, 'height': 1800};
      }
      if (call.method == 'getThumb') {
        requests.add(args);
        if (args['id'] == 'preview-late') return pending!.future;
        if (args['id'] == 'preview-corrupt') return Uint8List.fromList([0]);
        return _pixel;
      }
      throw StateError('Unexpected Photos call ${call.method}');
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('reselecting the active category retains marked photos', (
    tester,
  ) async {
    await _mount(tester, const SmartCleanView());
    await tester.tap(find.byKey(const ValueKey('select-review-first')));
    await tester.pump();
    expect(find.text('Selected items: 1'), findsOneWidget);
    await tester.tap(find.text('Photos').first);
    await tester.pump();
    expect(find.text('Selected items: 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'photo has identifiable checked semantics and keyboard toggles it',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await _mount(tester, const SmartCleanView());
      final card = find.byKey(const ValueKey('select-review-first'));
      final node = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.startsWith('Photos · 1 ·') == true,
      );
      expect(node, findsOneWidget);
      var data = tester.getSemantics(node).getSemanticsData();
      expect(data.flagsCollection.isChecked, isNot(CheckedState.none));
      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
      expect(data.label, contains('600 × 1800'));
      Focus.of(tester.element(card)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      data = tester.getSemantics(node).getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(find.text('Selected items: 1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        tester.getSemantics(node).getSemanticsData().flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      expect(find.text('Selected items: 1'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );

  testWidgets('partially indexed home never marks empty categories complete', (
    tester,
  ) async {
    await _mount(
      tester,
      const HomeView(),
      scanner: _Scanner(indexComplete: false),
    );
    expect(find.text('Done ✓'), findsNothing);
    expect(
      find.text(
        'The library is still being indexed. This category will update as indexing progresses.',
      ),
      findsNWidgets(2),
    );
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, const HomeView());
    // Photos have not been measured, so large files must remain pending.
    expect(find.text('Done ✓'), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'full preview requests native aspectFit independent of cropped grid cache',
    (tester) async {
      final asset = _photo('full-preview', thumbnail: _pixel);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAssetPreview(context, asset),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      final option = requests.single['option'] as Map;
      expect(option['resizeContentMode'], ResizeContentMode.fit.index);
      expect(option['width'], 1200);
      expect(option['height'], 1200);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byType(Image))),
      );
      await tester.pump();
      final decoded = tester.widget<RawImage>(find.byType(RawImage)).image!;
      expect(decoded.width, 8);
      expect(decoded.height, 24);
      expect(
        tester.widget<AssetThumbnail>(find.byType(AssetThumbnail)).fullImage,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'same ID with a fresh immutable model reloads its native preview',
    (tester) async {
      final original = _photo('edited-same-id');
      Widget subject(PhotoAsset asset) => _app(AssetThumbnail(asset: asset));
      await tester.pumpWidget(subject(original));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      await tester.pumpWidget(subject(original));
      await tester.pumpAndSettle();
      expect(
        requests,
        hasLength(1),
        reason: 'unchanged immutable model keeps its cache',
      );
      await tester.pumpWidget(subject(_photo('edited-same-id')));
      await tester.pumpAndSettle();
      expect(
        requests,
        hasLength(2),
        reason: 'a new same-ID model can represent an edit',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'an empty successful scan says completed rather than never scanned',
    (tester) async {
      await _mount(tester, const SmartCleanView(), scanner: _EmptyScanner());
      expect(find.text('Done ✓'), findsOneWidget);
      final strings = AppLocalizations.of(
        tester.element(find.byType(SmartCleanView)),
      );
      expect(
        find.text(strings.homeIndexedCountWithTotal(0, 0)),
        findsOneWidget,
      );
      expect(find.text('Start scanning your library'), findsNothing);
      expect(find.text('Start scan'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('deletion reports its waiting state and blocks route dismissal', (
    tester,
  ) async {
    final scanner = _DeletingScanner();
    await _mount(
      tester,
      const SmartCleanView(),
      scanner: scanner,
      subscriptions: _Pro(),
    );
    await tester.tap(find.byKey(const ValueKey('select-review-first')));
    await tester.pump();
    await tester.tap(find.text('Preview and delete 1 item'));
    await tester.pumpAndSettle();
    final strings = AppLocalizations.of(
      tester.element(find.byType(SmartCleanView)),
    );
    await tester.tap(find.text(strings.reviewConfirmCount(1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Deleting…'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    scanner.deletion.complete({});
    await tester.pumpAndSettle();
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    expect(
      find.text(
        'No items were deleted. The operation may have been canceled or failed.',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'thumbnail readiness requires decode and drops stale late callbacks',
    (tester) async {
      pending = Completer<Uint8List?>();
      final states = <bool>[];
      Widget subject(String id) =>
          _app(AssetThumbnail(asset: _photo(id), onPreviewReady: states.add));
      await tester.pumpWidget(subject('preview-late'));
      await tester.pump();
      expect(states, [false]);
      await tester.pumpWidget(subject('preview-corrupt'));
      await tester.pumpAndSettle();
      expect(states.where((ready) => ready), isEmpty);
      pending!.complete(_pixel);
      await tester.pumpAndSettle();
      expect(states.where((ready) => ready), isEmpty);
      await tester.pumpWidget(subject('preview-valid'));
      for (var i = 0; i < 10 && find.byType(Image).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      final image = tester.widget<Image>(find.byType(Image));
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byType(Image))),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      expect(states.last, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
