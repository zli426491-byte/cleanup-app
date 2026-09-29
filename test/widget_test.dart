import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/subscription_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() => messenger.setMockMethodCallHandler(photos, (call) async => 2));
  tearDown(() => messenger.setMockMethodCallHandler(photos, null));

  Widget buildSubject() => CleanupApp(
    hasCompletedOnboarding: false,
    subscriptionManager: SubscriptionManager(),
  );

  testWidgets('Onboarding renders first-run experience', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(const ValueKey('onboarding-get-started')), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
  });

  testWidgets('Onboarding advances from welcome to the feature steps', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('onboarding-step-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
  });
}
