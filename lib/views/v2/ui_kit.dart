import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

/// Full-width blue action pinned to the bottom of a page
/// (Let's go / Delete N / Great / Try Free).
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color = AppTheme.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.r16),
            onTap: enabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    else if (icon != null)
                      Icon(icon, color: Colors.white, size: 20),
                    if (loading || icon != null) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom area that keeps a [BigButton] above the home indicator.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: child,
  );
}

/// Light-blue card without shadow or border.
class TintCard extends StatelessWidget {
  const TintCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.r20,
    this.color = AppTheme.primaryLight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Blue pill with white text, used on thumbnails ("8 MB") and category cards
/// ("3 Videos (19.4 MB) ›").
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.text,
    this.detail,
    this.chevron = false,
  });

  final String text;
  final String? detail;
  final bool chevron;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 8, 6),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (chevron) ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
        ],
      ],
    ),
  );
}

/// Red rounded square with a white check when marked for deletion,
/// otherwise a hollow white square.
class DeleteMark extends StatelessWidget {
  const DeleteMark({super.key, required this.selected, this.size = 24});
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: selected ? AppTheme.danger : Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(size * 0.3),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: selected
        ? Icon(Icons.check_rounded, color: Colors.white, size: size * 0.7)
        : null,
  );
}

/// Tinted square back button used on pushed pages.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppTheme.textTitle, size: 22),
        ),
      ),
    ),
  );
}

/// Tinted pill button in page headers ("Select", "Select All", "Largest").
class HeaderPill extends StatelessWidget {
  const HeaderPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.primaryLight,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppTheme.textTitle),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Top bar for pushed pages: square back button on the left, optional
/// actions on the right, no title (the page shows a large title below).
class PageTopBar extends StatelessWidget {
  const PageTopBar({
    super.key,
    this.leading,
    this.trailing = const [],
    this.title,
  });

  final Widget? leading;
  final List<Widget> trailing;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final back =
        leading ??
        SquareIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Pills shrink and ellipsize instead of overflowing at large text.
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: back,
            ),
          ),
          const SizedBox(width: 12),
          if (title != null)
            Expanded(flex: 2, child: title!)
          else
            const Spacer(),
          for (var i = 0; i < trailing.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
