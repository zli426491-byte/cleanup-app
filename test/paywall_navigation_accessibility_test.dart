import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _products = [
  StoreProduct(
    AppConstants.yearlyProductId,
    'Yearly cleanup',
    'Yearly',
    990,
    'NT\$990',
    'TWD',
  ),
  StoreProduct(
    AppConstants.weeklyProductId,
    'Weekly cleanup',
    'Weekly',
    90,
    'NT\$90',
    'TWD',
  ),
];

class _PendingSubscription extends SubscriptionManager {
  final result = Completer<bool>();
  bool busy = false;
  bool restoring = false;

  @override
  bool get isPlaceholder => false;
  @override
  bool get isLoading => busy;
  @override
  SubscriptionOperation get operation => busy
      ? (restoring
            ? SubscriptionOperation.restoring
            : SubscriptionOperation.purchasing)
      : SubscriptionOperation.idle;
  @override
  List<StoreProduct> get storeProducts => _products;
  @override
  Future<List<Package>> loadProducts() async => [];

  Future<bool> _operation() async {
    busy = true;
    notifyListeners();
    final value = await result.future;
    busy = false;
    notifyListeners();
    return value;
  }

  @override
  Future<bool> restorePurchases() {
    restoring = true;
    return _operation();
  }

  @override
  Future<bool> purchaseStoreProduct(StoreProduct product) => _operation();
}

class _RouteObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

Future<void> _openPaywall(
  WidgetTester tester,
  _PendingSubscription subscriptions,
  _RouteObserver observer, {
  Locale locale = const Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
  ),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SubscriptionManager>.value(
      value: subscriptions,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Review photos')),
                    body: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PaywallView(),
                        ),
                      ),
                      child: const Text('Open paywall'),
                    ),
                  ),
                ),
              ),
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open review'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open paywall'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '41',
      buildSignature: '',
    );
  });

  for (final operation in ['restore', 'purchase']) {
    testWidgets(
      '$operation completing during dismissal preserves review route',
      (tester) async {
        final subscriptions = _PendingSubscription();
        final observer = _RouteObserver();
        await _openPaywall(tester, subscriptions, observer);
        final action = find.text(
          operation == 'restore'
              ? '恢復購買'
              : tester
                    .element(find.byType(PaywallView))
                    .l10n
                    .paywallSubscribeYearly('NT\$990'),
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        expect(subscriptions.busy, isTrue);
        expect(
          find.text(
            operation == 'restore'
                ? tester.element(find.byType(PaywallView)).l10n.paywallRestoring
                : tester
                      .element(find.byType(PaywallView))
                      .l10n
                      .paywallWaitingForStore,
          ),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('關閉'));
        await tester.pump(const Duration(milliseconds: 16));
        // A popped page stays mounted during its reverse transition. Complete
        // before disposal to catch a second pop from the late transaction.
        expect(find.byType(PaywallView), findsOneWidget);
        subscriptions.result.complete(true);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(observer.pops, 1);
        expect(find.text('Review photos'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        subscriptions.dispose();
      },
    );
  }

  testWidgets('repeated close callbacks pop only the paywall', (tester) async {
    final subscriptions = _PendingSubscription();
    final observer = _RouteObserver();
    await _openPaywall(tester, subscriptions, observer);
    final close = tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
        .onPressed!;
    close();
    close();
    await tester.pumpAndSettle();
    expect(observer.pops, 1);
    expect(find.text('Review photos'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    subscriptions.dispose();
  });

  testWidgets('external back and a late restore do not pop the review route', (
    tester,
  ) async {
    final subscriptions = _PendingSubscription();
    final observer = _RouteObserver();
    await _openPaywall(tester, subscriptions, observer);
    await tester.ensureVisible(find.text('恢復購買'));
    await tester.tap(find.text('恢復購買'));
    await tester.pump();
    Navigator.of(tester.element(find.byType(PaywallView))).pop();
    await tester.pump(const Duration(milliseconds: 16));
    subscriptions.result.complete(true);
    await tester.pumpAndSettle();
    expect(observer.pops, 1);
    expect(find.text('Review photos'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    subscriptions.dispose();
  });

  testWidgets(
    'keyboard plan selection exposes one selected accessible option',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final subscriptions = _PendingSubscription();
      await _openPaywall(tester, subscriptions, _RouteObserver());
      final yearly = find.byKey(
        const ValueKey('paywall-plan-${AppConstants.yearlyProductId}'),
      );
      final weekly = find.byKey(
        const ValueKey('paywall-plan-${AppConstants.weeklyProductId}'),
      );
      await tester.ensureVisible(weekly);
      expect(
        tester
            .getSemantics(yearly)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      final focusElement = tester.element(
        find.descendant(of: weekly, matching: find.byType(Container)).first,
      );
      Focus.of(focusElement).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final selected = tester.getSemantics(weekly).getSemanticsData();
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(selected.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(selected.flagsCollection.isButton, isTrue);
      expect(selected.hasAction(SemanticsAction.tap), isTrue);
      expect(selected.label, contains('NT\$90'));
      expect(
        tester
            .getSemantics(yearly)
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      subscriptions.dispose();
      semantics.dispose();
    },
  );

  testWidgets(
    'subscription action is accessible and states price, period and renewal',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final subscriptions = _PendingSubscription();
      await _openPaywall(tester, subscriptions, _RouteObserver());
      final strings = tester.element(find.byType(PaywallView)).l10n;
      expect(find.text(strings.paywallBestValue), findsNothing);
      expect(find.text(strings.paywallFreePreviewNote), findsOneWidget);
      expect(
        find.text(strings.paywallYearlyRenewal('NT\$990')),
        findsOneWidget,
      );
      final action = find.text(strings.paywallSubscribeYearly('NT\$990'));
      await tester.ensureVisible(action);
      final node = tester.getSemantics(action);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(subscriptions.busy, isTrue);
      expect(find.text(strings.paywallWaitingForStore), findsOneWidget);
      subscriptions.result.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      subscriptions.dispose();
      semantics.dispose();
    },
  );

  for (final locale in LocaleController.supportedLocales) {
    for (final size in [const Size(320, 568), const Size(1366, 1024)]) {
      testWidgets(
        '${locale.toLanguageTag()} real plans fit $size at 200% text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final subscriptions = _PendingSubscription();
          await _openPaywall(
            tester,
            subscriptions,
            _RouteObserver(),
            locale: locale,
            textScale: 2,
          );
          final weekly = find.byKey(
            const ValueKey('paywall-plan-${AppConstants.weeklyProductId}'),
          );
          await tester.ensureVisible(weekly);
          await tester.pump();
          expect(find.text('NT\$90'), findsOneWidget);
          expect(
            Directionality.of(tester.element(weekly)),
            ['ar', 'he'].contains(locale.languageCode)
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          expect(tester.getRect(weekly).width, lessThanOrEqualTo(640 - 48));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          subscriptions.dispose();
        },
      );
    }
  }
}
