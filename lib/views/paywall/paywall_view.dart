import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../home/main_tab_view.dart';

class PaywallView extends StatelessWidget {
  final bool fromOnboarding;
  const PaywallView({super.key, this.fromOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _dismiss(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Cleanup Pro',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('解鎖無限清理功能',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),

            ..._features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(f.$1, color: f.$3, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f.$2)),
                      const Icon(Icons.check_circle,
                          color: AppTheme.success, size: 18),
                    ],
                  ),
                )),
            const SizedBox(height: 32),

            _PlanCard(title: '週訂閱', price: '\$7.99/週', isSelected: true, isBestValue: false, onTap: () {}),
            const SizedBox(height: 8),
            _PlanCard(title: '年訂閱', price: '\$29.99/年', isSelected: false, isBestValue: true, onTap: () {}),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final offerings = await Purchases.getOfferings();
                    final package = offerings.current?.availablePackages.firstOrNull;
                    if (package != null) {
                      await sub.purchase(package);
                    }
                    if (context.mounted && sub.isPro) _dismiss(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('開始免費試用',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('7 天免費試用，之後自動續訂',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text('隨時可在設定中取消',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                    onPressed: () => sub.restorePurchases(),
                    child: const Text('恢復購買', style: TextStyle(fontSize: 12))),
                TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://zli426491-byte.github.io/cleanup-app/')),
                    child: const Text('隱私政策', style: TextStyle(fontSize: 12))),
                TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://zli426491-byte.github.io/cleanup-app/')),
                    child: const Text('使用條款', style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _dismiss(BuildContext context) async {
    if (fromOnboarding) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainTabView()),
          (route) => false,
        );
      }
    } else {
      Navigator.pop(context);
    }
  }

  static const _features = [
    (Icons.copy, '無限重複照片清理', AppTheme.danger),
    (Icons.photo_library, '智慧相似照片偵測', AppTheme.warning),
    (Icons.compress, '照片與影片壓縮', AppTheme.accent),
    (Icons.people, '聯絡人合併清理', AppTheme.primary),
    (Icons.lock, '私密空間保管庫', AppTheme.success),
    (Icons.screenshot, '螢幕截圖批量刪除', Colors.teal),
  ];
}

class _PlanCard extends StatelessWidget {
  final String title, price;
  final bool isSelected, isBestValue;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title, required this.price,
    required this.isSelected, required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isBestValue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('最超值',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
