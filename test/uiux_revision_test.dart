import 'dart:typed_data';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/home/main_tab_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PhotoAsset _photo(String id, {bool corrupt = false}) => PhotoAsset(
  id: id,
  width: 100,
  height: 200,
  size: 0,
  createDate: DateTime(2026),
  modifiedDate: DateTime(2026),
  type: AssetType.image,
  thumbnail: corrupt
      ? Uint8List.fromList([1])
      : Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 16))),
);

class _Scanner extends PhotoScannerService {
  _Scanner({List<PhotoAsset> assets = const []}) {
    replace(assets);
  }
  late ScanResult result;
  bool denied = false;
  bool scanning = false;
  int starts = 0;
  int settings = 0;
  @override
  ScanResult get scanResult => result;
  @override
  bool get nativeOriginalAnalysisAvailable => false;
  @override
  bool get isScanning => scanning;
  @override
  bool get permissionDenied => denied;
  @override
  Future<bool> openPhotoSettings() async {
    settings++;
    return true;
  }

  @override
  Future<void> startFullScan() async {
    starts++;
    scanning = true;
    notifyListeners();
  }

  void replace(List<PhotoAsset> assets) {
    result = ScanResult(
      allAssets: assets,
      duplicateGroups: [],
      similarGroups: [],
      screenshots: assets,
      largeFiles: [],
      videos: [],
      blurryPhotos: [],
      darkPhotos: [],
      overexposedPhotos: [],
      totalSavingsEstimate: 0,
    );
    notifyListeners();
  }

  void allow() {
    denied = false;
    notifyListeners();
  }
}

Future<void> _mount(WidgetTester tester, _Scanner scanner, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Cleanup',
    packageName: 'test.cleanup',
    version: '1.1.3',
    buildNumber: 'audit',
    buildSignature: '',
  );
  final subscription = SubscriptionManager();
  final locales = LocaleController(initialLocale: const Locale('en'));
  addTearDown(scanner.dispose);
  addTearDown(subscription.dispose);
  addTearDown(locales.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
        ChangeNotifierProvider<LocaleController>.value(value: locales),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _decode(WidgetTester tester) async {
  final context = tester.element(find.byType(SmartCleanView));
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context, onError: (_, _) {});
    }
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('fresh Home has one real scan action, no empty review detour', (
    tester,
  ) async {
    final scanner = _Scanner();
    await _mount(tester, scanner, const HomeView());
    expect(find.byKey(const ValueKey('home-scan-start')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-swipe-entry')),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('home-scan-start')));
    await tester.pump();
    expect(scanner.starts, 1);
    expect(find.byType(SmartCleanView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'denied Home opens Settings and updates when permission is restored',
    (tester) async {
      final scanner = _Scanner()..denied = true;
      await _mount(tester, scanner, const HomeView());
      await tester.tap(find.byKey(const ValueKey('open-photo-settings')));
      await tester.pump();
      expect(scanner.settings, 1);
      expect(find.textContaining('Read 0'), findsNothing);
      scanner.allow();
      await tester.pump();
      expect(find.byKey(const ValueKey('open-photo-settings')), findsNothing);
      expect(find.byKey(const ValueKey('home-scan-start')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Home tools reuse the cleanup tab and preserve category context',
    (tester) async {
      final scanner = _Scanner();
      await _mount(tester, scanner, const MainTabView());
      await tester.ensureVisible(find.text('Large files').first);
      await tester.tap(find.text('Large files').first);
      await tester.pumpAndSettle();
      expect(find.byType(SmartCleanView, skipOffstage: false), findsOneWidget);
      expect(
        tester
            .widget<SmartCleanView>(find.byType(SmartCleanView))
            .initialCategory,
        'largeFiles',
      );
      await tester.tap(find.byKey(const ValueKey('main-tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SmartCleanView>(find.byType(SmartCleanView))
            .initialCategory,
        'largeFiles',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'unreadable grid assets cannot be selected individually or in bulk',
    (tester) async {
      final scanner = _Scanner(assets: [_photo('bad', corrupt: true)]);
      await _mount(tester, scanner, const SmartCleanView());
      await _decode(tester);
      final toggle = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('select-bad')),
      );
      expect(toggle.onTap, isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('select-current-category')),
      );
      await tester.tap(find.byKey(const ValueKey('select-current-category')));
      await tester.pump();
      expect(find.textContaining('Selected items:'), findsNothing);
      expect(scanner.isDeleting, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'only decoded current-version assets enter selection and edits invalidate it',
    (tester) async {
      final scanner = _Scanner(assets: [_photo('edited')]);
      await _mount(tester, scanner, const SmartCleanView());
      await _decode(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('select-edited')));
      await tester.tap(find.byKey(const ValueKey('select-edited')));
      await tester.pump();
      expect(find.text('Selected items: 1'), findsOneWidget);
      scanner.replace([_photo('edited', corrupt: true)]);
      await tester.pump();
      await _decode(tester);
      expect(find.text('Selected items: 1'), findsNothing);
      expect(
        tester
            .widget<GestureDetector>(
              find.byKey(const ValueKey('select-edited')),
            )
            .onTap,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
