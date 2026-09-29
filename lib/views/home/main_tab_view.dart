import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import '../home/home_view.dart';
import '../v2/extras_view.dart';
import '../v2/optimize_view.dart';
import '../../utils/app_theme.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});
  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _i = 0;

  static const _pages = [HomeView(), OptimizeTabView(), ExtrasView()];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _i,
        children: [
          for (var index = 0; index < _pages.length; index++)
            TickerMode(enabled: index == _i, child: _pages[index]),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              children: [
                _tab(0, Icons.home_rounded, l10n.navHome),
                _tab(1, Icons.video_library_rounded, l10n.navOptimize),
                _tab(2, Icons.more_horiz_rounded, l10n.navExtras),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int idx, IconData icon, String label) {
    final selected = _i == idx;
    final color = selected ? AppTheme.primary : AppTheme.textMuted;
    return Expanded(
      child: Semantics(
        key: ValueKey('main-tab-$idx'),
        button: true,
        selected: selected,
        child: InkWell(
          onTap: () => setState(() => _i = idx),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
