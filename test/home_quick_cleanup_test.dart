import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class _IndexedScanner extends PhotoScannerService {
  _IndexedScanner({this.scanning = false});
  final bool scanning;
  @override
  bool get isScanning => scanning;
  @override
  bool get hasCompletedScan => !scanning;
  @override
  int get scannedAssetCount => 2;
  @override
  int? get availableAssetCount => 2;
  @override
  ScanResult get scanResult => ScanResult(
    allAssets: [
      for (final type in [AssetType.image, AssetType.video])
        PhotoAsset(
          id: type.name,
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: type,
          thumbnail: Uint8List.fromList(
            img.encodePng(img.Image(width: 8, height: 8)),
          ),
        ),
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
}

void main() {
  for (final scanning in [false, true]) {
    testWidgets(
      'home swipe entry is explicit and ${scanning ? 'disabled while scanning' : 'opens image review directly'}',
      (tester) async {
        final scanner = _IndexedScanner(scanning: scanning);
        final subscriptions = SubscriptionManager();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscriptions,
              ),
            ],
            child: MaterialApp(
              locale: const Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeView(),
            ),
          ),
        );
        await tester.pump();
        final entry = find.byKey(const ValueKey('home-swipe-entry'));
        final start = find.descendant(
          of: entry,
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(start);
        await tester.pump();
        expect(find.text('逐張左右滑動，比點選縮圖更快。'), findsOneWidget);
        expect(find.text('開始滑動整理'), findsOneWidget);
        expect(tester.widget<FilledButton>(start).onPressed == null, scanning);
        if (!scanning) {
          await tester.tap(start);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final review = tester.widget<SwipeCleanView>(
            find.byType(SwipeCleanView),
          );
          expect(review.assets.map((asset) => asset.id), ['image']);
          expect(review.categoryId, 'photos');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        scanner.dispose();
        subscriptions.dispose();
      },
    );
  }
}
