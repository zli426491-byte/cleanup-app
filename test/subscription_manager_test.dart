import 'package:flutter_test/flutter_test.dart';

import 'package:cleanup_app/services/subscription_manager.dart';

void main() {
  test('SubscriptionManager stays in placeholder mode without RevenueCat keys', () async {
    final manager = SubscriptionManager();

    await manager.init(isIos: true);

    expect(manager.isPlaceholder, isTrue);
    expect(manager.isPro, isFalse);
    expect(manager.availablePackages, isEmpty);
    expect(manager.statusMessage, contains('RevenueCat API Key'));
  });
}
