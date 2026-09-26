import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _PartialScanner extends PhotoScannerService {
  @override
  bool get hasCompletedScan => true;

  @override
  int? get availableAssetCount => 5000;

  @override
  String? get scanNotice => '本次僅讀取部分項目，請預覽後再決定。';
}

void main() {
  for (final device in {
    'iPhone': const Size(390, 844),
    'iPad': const Size(1024, 1366),
  }.entries) {
    testWidgets(
      '${device.key}: partial scan is disclosed and preview opens a real review page',
      (tester) async {
        tester.view.physicalSize = device.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scanner = _PartialScanner();
        final subscription = SubscriptionManager();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscription,
              ),
            ],
            child: const MaterialApp(home: HomeView()),
          ),
        );
        await tester.pump();

        expect(find.textContaining('可存取共 5000 個'), findsOneWidget);
        expect(find.textContaining('僅讀取部分項目'), findsOneWidget);
        expect(find.text('預估可釋放'), findsNothing);
        expect(find.text('模糊照片'), findsNothing);
        expect(find.text('清理信箱'), findsNothing);
        expect(find.text('清理行事曆'), findsNothing);

        await tester.ensureVisible(find.text('預覽並整理'));
        await tester.tap(find.text('預覽並整理'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(SmartCleanView), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        scanner.dispose();
        subscription.dispose();
      },
    );
  }
}
