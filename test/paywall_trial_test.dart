import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _yearly = StoreProduct(
  AppConstants.yearlyProductId,
  'Yearly cleanup',
  'Yearly',
  990,
  'NT\$990',
  'TWD',
);
const _weeklyWithTrial = StoreProduct(
  AppConstants.weeklyProductId,
  'Weekly cleanup',
  'Weekly',
  90,
  'NT\$90',
  'TWD',
  introductoryPrice: IntroductoryPrice(
    0,
    'NT\$0',
    'P1W',
    1,
    PeriodUnit.week,
    1,
  ),
);

class _Store extends SubscriptionManager {
  _Store({required this.eligible});
  final bool eligible;
  bool pro = false;

  @override
  bool get isPro => pro;
  @override
  bool get isPlaceholder => false;
  @override
  bool get isLoading => false;
  @override
  bool get isInitializing => false;
  @override
  List<StoreProduct> get storeProducts => const [_yearly, _weeklyWithTrial];
  @override
  Future<List<Package>> loadProducts() async => const [];
  @override
  int? freeTrialDays(StoreProduct product) =>
      eligible && product.introductoryPrice?.price == 0 ? 7 : null;
  @override
  Future<bool> purchaseStoreProduct(StoreProduct product) async {
    pro = true;
    notifyListeners();
    return true;
  }
}

/// Both plans have a trial, with different lengths (yearly 3, weekly 7).
class _TwoTrialStore extends _Store {
  _TwoTrialStore() : super(eligible: true);
  @override
  int? freeTrialDays(StoreProduct product) =>
      product.identifier == AppConstants.yearlyProductId ? 3 : 7;
}

Future<AppLocalizations> _pump(
  WidgetTester tester,
  SubscriptionManager store,
  Widget paywall,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scanner = PhotoScannerService();
  addTearDown(scanner.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionManager>.value(value: store),
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: paywall,
      ),
    ),
  );
  await tester.pump();
  return tester.element(find.byType(PaywallView)).l10n;
}

Future<BuildContext> _pumpUnlockHost(
  WidgetTester tester,
  SubscriptionManager store,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scanner = PhotoScannerService();
  addTearDown(scanner.dispose);
  late BuildContext host;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionManager>.value(value: store),
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            host = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return host;
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '46',
      buildSignature: '',
    );
  });

  test('a store intro offer alone never counts as an eligible trial', () {
    final manager = SubscriptionManager();
    expect(manager.freeTrialDays(_weeklyWithTrial), isNull);
    expect(manager.freeTrialDays(_yearly), isNull);
    manager.dispose();
  });

  testWidgets('eligible customers see the trial plan preselected', (
    tester,
  ) async {
    final store = _Store(eligible: true);
    final l10n = await _pump(tester, store, const PaywallView());
    expect(find.text(l10n.v2UnlockTitle), findsOneWidget);
    expect(find.text(l10n.v2FreeTrialDays(7)), findsOneWidget);
    expect(find.text(l10n.v2StartFreeTrial(7)), findsOneWidget);
    expect(find.text(l10n.paywallWeeklyRenewal('NT\$90')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('ineligible customers are never promised a free trial', (
    tester,
  ) async {
    final store = _Store(eligible: false);
    final l10n = await _pump(tester, store, const PaywallView());
    expect(find.textContaining('free trial'), findsNothing);
    expect(find.text(l10n.paywallSubscribeYearly('NT\$990')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('onboarding variant shows the trial timeline and Try Free', (
    tester,
  ) async {
    final store = _Store(eligible: true);
    final l10n = await _pump(
      tester,
      store,
      const PaywallView(fromOnboarding: true),
    );
    expect(find.text(l10n.v2CleanYourStorage), findsOneWidget);
    expect(find.text(l10n.v2TrialEnabled), findsOneWidget);
    expect(find.text(l10n.v2DueToday), findsOneWidget);
    expect(find.text('NT\$0'), findsOneWidget);
    expect(find.text(l10n.v2TryFree), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('onboarding variant without a trial lists the plans instead', (
    tester,
  ) async {
    final store = _Store(eligible: false);
    final l10n = await _pump(
      tester,
      store,
      const PaywallView(fromOnboarding: true),
    );
    expect(find.text(l10n.v2TrialEnabled), findsNothing);
    expect(find.text(l10n.v2PerYear('NT\$990')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('the unlock paywall has no extra free-continue button', (
    tester,
  ) async {
    // Like the reference app, the X itself continues the free flow.
    final store = _Store(eligible: false);
    await _pump(tester, store, const PaywallView());
    expect(find.byKey(const ValueKey('paywall-continue-free')), findsNothing);
    expect(find.byKey(const ValueKey('paywall-close')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets(
    'closing the unlock offer reports cancelled',
    (tester) async {
      final store = _Store(eligible: false);
      final host = await _pumpUnlockHost(tester, store);
      final result = PaywallView.showUnlock(
        host,
        source: 'test',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paywall-close')));
      await tester.pumpAndSettle();
      expect(await result, PaywallUnlockResult.cancelled);
      store.dispose();
    },
  );

  testWidgets('a successful purchase is distinct from closing', (
    tester,
  ) async {
    final store = _Store(eligible: false);
    final host = await _pumpUnlockHost(tester, store);
    final result = PaywallView.showUnlock(
      host,
      source: 'test',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(host.l10n.paywallSubscribeYearly('NT\$990')));
    await tester.pumpAndSettle();
    expect(await result, PaywallUnlockResult.purchased);
    store.dispose();
  });

  testWidgets(
    'the onboarding teaser promises the trial of the preselected plan',
    (tester) async {
      final store = _TwoTrialStore();
      // The teaser must not advertise the longest trial (7) when the page
      // preselects the yearly plan with 3 days.
      expect(PaywallView.leadingTrialDays(store), 3);
      final l10n = await _pump(
        tester,
        store,
        const PaywallView(fromOnboarding: true),
      );
      expect(find.text(l10n.v2DaysFree(3)), findsOneWidget);
      expect(find.text(l10n.v2DaysFree(7)), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets('system back also cancels an unlock offer', (tester) async {
    final store = _Store(eligible: false);
    final host = await _pumpUnlockHost(tester, store);
    final result = PaywallView.showUnlock(
      host,
      source: 'test',
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, PaywallUnlockResult.cancelled);
    store.dispose();
  });
}
