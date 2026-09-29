import 'dart:ui' show Tristate;

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/views/v2/category_grid_view.dart';
import 'package:cleanup_app/views/v2/cleanup_category.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

final _preview = img.encodePng(img.Image(width: 8, height: 8));

PhotoAsset _photo(String id, {bool screenshot = false}) => PhotoAsset(
  id: id,
  width: 100,
  height: 100,
  size: 1024,
  sizeKnown: true,
  createDate: DateTime(2026, 9, 29),
  type: AssetType.image,
  isScreenshot: screenshot,
  thumbnail: _preview,
);

ScanResult _result(
  List<PhotoAsset> photos, {
  List<DuplicateGroup> groups = const [],
}) => ScanResult(
  allAssets: photos,
  duplicateGroups: groups,
  similarGroups: const [],
  screenshots: photos.where((p) => p.isScreenshot).toList(),
  largeFiles: const [],
  videos: const [],
  blurryPhotos: const [],
  darkPhotos: const [],
  overexposedPhotos: const [],
  totalSavingsEstimate: 0,
);

class _Scanner extends PhotoScannerService {
  _Scanner(this.result);
  ScanResult result;
  ScanResult? resultAfterPause;
  bool scanning = false;
  bool continuous = false;
  bool originalContinuous = false;
  int pauses = 0;

  @override
  ScanResult get scanResult => result;
  @override
  bool get isScanning => scanning;
  @override
  bool get isContinuousScanning => continuous || originalContinuous;

  @override
  Future<void> pauseContinuousScan() async {
    pauses++;
    scanning = false;
    continuous = false;
    originalContinuous = false;
    if (resultAfterPause case final next?) replace(next);
  }

  void replace(ScanResult next) {
    result = next;
    notifyListeners();
  }
}

Future<void> _host(
  WidgetTester tester,
  _Scanner scanner,
  Widget home, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ChangeNotifierProvider<PhotoScannerService>.value(
      value: scanner,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('grid select all verifies offscreen photos before delete', (
    tester,
  ) async {
    final photos = [
      for (var i = 0; i < 30; i++) _photo('p$i', screenshot: true),
    ];
    final scanner = _Scanner(_result(photos));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await _host(
      tester,
      scanner,
      const CategoryGridView(category: CleanupCategory.screenshots),
    );
    expect(find.byKey(const ValueKey('grid-tile-p29')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('grid-select-toggle')));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('grid-select-all')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    for (
      var i = 0;
      i < 100 && find.text('Delete 30 Items').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Delete 30 Items'), findsOneWidget);
    expect(find.byKey(const ValueKey('grid-tile-p29')), findsNothing);
  });

  testWidgets('a new scan snapshot cancels unfinished select-all validation', (
    tester,
  ) async {
    final photos = [
      for (var i = 0; i < 30; i++) _photo('old-$i', screenshot: true),
    ];
    final scanner = _Scanner(_result(photos));
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await _host(
      tester,
      scanner,
      const CategoryGridView(category: CleanupCategory.screenshots),
    );
    await tester.tap(find.byKey(const ValueKey('grid-select-toggle')));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('grid-select-all')));
      scanner.replace(_result([_photo('new', screenshot: true)]));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('grid-delete')), findsNothing);
    expect(find.text('Select All'), findsOneWidget);
  });

  testWidgets('select all pauses scanning and uses the resulting snapshot', (
    tester,
  ) async {
    final original = [
      for (var i = 0; i < 10; i++) _photo('old-$i', screenshot: true),
    ];
    final latest = [
      for (var i = 0; i < 12; i++) _photo('new-$i', screenshot: true),
    ];
    final scanner = _Scanner(_result(original))
      ..scanning = true
      ..continuous = true
      ..resultAfterPause = _result(latest);
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await _host(
      tester,
      scanner,
      const CategoryGridView(category: CleanupCategory.screenshots),
    );
    await tester.tap(find.byKey(const ValueKey('grid-select-toggle')));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('grid-select-all')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(scanner.pauses, 1);
    expect(find.text('Delete 12 Items'), findsOneWidget);
  });

  testWidgets('select all pauses original verification before using snapshot', (
    tester,
  ) async {
    final original = [
      for (var i = 0; i < 10; i++) _photo('old-$i', screenshot: true),
    ];
    final latest = [
      for (var i = 0; i < 12; i++) _photo('new-$i', screenshot: true),
    ];
    final scanner = _Scanner(_result(original))
      ..scanning = true
      ..originalContinuous = true
      ..resultAfterPause = _result(latest);
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await _host(
      tester,
      scanner,
      const CategoryGridView(category: CleanupCategory.screenshots),
    );
    await tester.tap(find.byKey(const ValueKey('grid-select-toggle')));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('grid-select-all')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(scanner.pauses, 1);
    expect(scanner.originalContinuous, isFalse);
    expect(find.text('Delete 12 Items'), findsOneWidget);
  });

  testWidgets('a group always retains one photo, including after select all', (
    tester,
  ) async {
    final best = _photo('best');
    final other = _photo('other');
    final scanner = _Scanner(
      _result(
        [best, other],
        groups: [
          DuplicateGroup(
            hash: 'pair',
            assets: [best, other],
            bestAssetId: best.id,
          ),
        ],
      ),
    );
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await _host(
      tester,
      scanner,
      const GroupReviewView(
        title: 'Duplicates',
        sections: [CleanupCategory.duplicates],
      ),
    );
    final context = tester.element(find.byType(GroupReviewView));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    bool selected(String id) =>
        tester
            .getSemantics(find.byKey(ValueKey('group-tile-$id')))
            .getSemanticsData()
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;

    expect(selected('best'), isFalse);
    expect(selected('other'), isTrue);
    await tester.tap(find.byKey(const ValueKey('group-tile-best')));
    await tester.pump();
    expect(selected('best'), isFalse);
    await tester.tap(find.byKey(const ValueKey('group-tile-other')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('group-tile-best')));
    await tester.pump();
    expect(selected('best'), isTrue);
    expect(selected('other'), isFalse);
    await tester.tap(find.byKey(const ValueKey('group-select-all')));
    await tester.pump();
    expect(selected('best'), isFalse);
    expect(selected('other'), isTrue);
    semantics.dispose();
  });

  testWidgets('group suggestions include offscreen pairs after validation', (
    tester,
  ) async {
    final photos = <PhotoAsset>[];
    final groups = <DuplicateGroup>[];
    for (var i = 0; i < 20; i++) {
      final best = _photo('best-$i');
      final other = _photo('other-$i');
      photos.addAll([best, other]);
      groups.add(
        DuplicateGroup(
          hash: 'pair-$i',
          assets: [best, other],
          bestAssetId: best.id,
        ),
      );
    }
    final scanner = _Scanner(_result(photos, groups: groups))
      ..scanning = true
      ..continuous = true;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      scanner.dispose();
    });
    await tester.runAsync(() async {
      await _host(
        tester,
        scanner,
        const GroupReviewView(
          title: 'Duplicates',
          sections: [CleanupCategory.duplicates],
        ),
        settle: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(scanner.pauses, 1);
    expect(
      find.byKey(const ValueKey('group-card-duplicate:pair-19')),
      findsNothing,
    );
    // The button counts the selected items (one per pair).
    expect(find.text('Delete 20 Items'), findsOneWidget);
  });
}
