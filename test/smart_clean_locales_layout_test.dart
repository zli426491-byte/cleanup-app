import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

class _PendingScanner extends PhotoScannerService {
  _PendingScanner()
    : _result = ScanResult(
        allAssets: [
          PhotoAsset(
            id: 'pending',
            width: 1200,
            height: 900,
            size: 0,
            createDate: DateTime(2026, 1, 2),
            type: AssetType.image,
            thumbnail: img.encodePng(img.Image(width: 8, height: 8)),
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

  final ScanResult _result;

  @override
  ScanResult get scanResult => _result;

  @override
  bool get isScanning => true;

  @override
  int get scannedAssetCount => 1;

  @override
  int? get availableAssetCount => 42638;

  @override
  int get totalPhotoCount => 1;

  @override
  int get pendingHashAssetCount => 1;

  @override
  int get pendingSizeAssetCount => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pending results fit phone and tablet in every shipped locale', (
    tester,
  ) async {
    final scanner = _PendingScanner();
    final subscription = SubscriptionManager();
    addTearDown(scanner.dispose);
    addTearDown(subscription.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in [const Size(390, 844), const Size(768, 1024)]) {
      await tester.binding.setSurfaceSize(size);
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscription,
              ),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.2)),
                child: child!,
              ),
              home: const SmartCleanView(initialCategory: 'duplicates'),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Smart Cleanup overflowed for $locale at ${size.width}px',
        );
        expect(
          find.byKey(const ValueKey('scan-pause-review-action')),
          findsOneWidget,
          reason: 'Review action is missing for $locale at ${size.width}px',
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
