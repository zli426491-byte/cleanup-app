import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final device in {
    'iPhone landscape': const Size(844, 390),
    'iPad compact window': const Size(320, 480),
  }.entries) {
    testWidgets(
      '${device.key} can read every onboarding page without overflow',
      (tester) async {
        tester.view.physicalSize = device.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MaterialApp(home: OnboardingView()));
        await tester.pump();

        for (var page = 1; page <= 4; page++) {
          expect(find.text('$page/4'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(find.text(page == 4 ? '開始使用' : '繼續'), findsOneWidget);
          if (page < 4) {
            await tester.tap(find.text('繼續'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
