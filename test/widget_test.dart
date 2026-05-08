import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/subscription_manager.dart';

void main() {
  Widget buildSubject() => CleanupApp(
        hasCompletedOnboarding: false,
        subscriptionManager: SubscriptionManager(),
      );

  testWidgets('Onboarding renders first-run experience', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('1/4'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });

  testWidgets('Onboarding advances through pages', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2/4'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
  });
}
