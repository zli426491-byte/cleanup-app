import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../utils/app_theme.dart';
import '../secret_space/secret_space_view.dart';
import '../tools/charging_animation_view.dart';
import 'ui_kit.dart';

/// "Extras" tab: utilities and the private library.
class ExtrasView extends StatelessWidget {
  const ExtrasView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Text(l10n.v2ExtrasTitle, style: AppTheme.largeTitle),
            const SizedBox(height: 24),
            _Section(label: l10n.v2ExtrasUtilities),
            _ExtraRow(
              key: const ValueKey('extras-charging'),
              icon: Icons.battery_charging_full_rounded,
              title: l10n.v2ChargingTitle,
              subtitle: l10n.v2ChargingBody,
              builder: (_) => const ChargingAnimationView(),
            ),
            const SizedBox(height: 20),
            _Section(label: l10n.v2ExtrasPrivate),
            _ExtraRow(
              key: const ValueKey('extras-secret'),
              icon: Icons.lock_outline_rounded,
              title: l10n.v2SecretTitle,
              subtitle: l10n.v2SecretBody,
              builder: (_) => const SecretSpaceView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
    child: Text(label.toUpperCase(), style: AppTheme.sectionLabel),
  );
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TintCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: builder)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textTitle),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.heading3),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.small),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textTitle),
        ],
      ),
    ),
  );
}
