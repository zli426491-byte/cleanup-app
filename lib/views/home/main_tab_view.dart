import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import '../home/home_view.dart';
import '../scanner/smart_clean_view.dart';
import '../settings/settings_view.dart';
import '../../utils/app_theme.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});
  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _i = 0;
  final _pages = const [HomeView(), SmartCleanView(), SettingsView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tab(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  context.l10n.navHome,
                ),
                _tab(
                  1,
                  Icons.auto_awesome_outlined,
                  Icons.auto_awesome_rounded,
                  context.l10n.navClean,
                ),
                _tab(
                  2,
                  Icons.settings_outlined,
                  Icons.settings_rounded,
                  context.l10n.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int idx, IconData outline, IconData filled, String label) {
    final selected = _i == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _i = idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? filled : outline,
                size: 22,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
