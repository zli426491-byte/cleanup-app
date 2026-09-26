import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  StorageInfo? _storage;
  String _version = '讀取中';

  @override
  void initState() {
    super.initState();
    StorageInfo.current().then((s) {
      if (mounted) setState(() => _storage = s);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              sub.isPro
                  ? Icons.workspace_premium
                  : Icons.workspace_premium_outlined,
              color: sub.isPro ? Colors.amber : Colors.grey,
            ),
            title: Text(
              sub.isPro ? 'Cleanup Pro' : '免費方案',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: sub.isPro
                ? null
                : ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallView()),
                    ),
                    child: const Text('升級'),
                  ),
          ),
          const Divider(),

          if (_storage != null && !_storage!.isEstimate) ...[
            _settingsHeader('儲存空間'),
            _settingsRow('總計', _storage!.totalSpaceFormatted),
            _settingsRow('已使用', _storage!.usedSpaceFormatted),
            _settingsRow(
              '可用',
              _storage!.freeSpaceFormatted,
              valueColor: AppTheme.success,
            ),
            const Divider(),
          ],

          _settingsHeader('一般'),
          ListTile(
            title: Text(sub.isLoading ? '正在處理訂閱…' : '恢復購買'),
            onTap: sub.isLoading
                ? null
                : () async {
                    final restored = await sub.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          restored ? '已恢復 Pro 訂閱。' : sub.statusMessage,
                        ),
                      ),
                    );
                  },
          ),
          ListTile(
            title: const Text('隱私權政策'),
            onTap: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
          ),
          ListTile(
            title: const Text('使用條款'),
            onTap: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
          ),
          ListTile(
            title: const Text('給我們評分'),
            onTap: () async {
              final review = InAppReview.instance;
              if (await review.isAvailable()) review.requestReview();
            },
          ),
          const Divider(),

          _settingsHeader('關於'),
          _settingsRow('版本', _version),
        ],
      ),
    );
  }

  Widget _settingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {Color? valueColor}) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(color: valueColor ?? Colors.grey[600]),
      ),
    );
  }
}
