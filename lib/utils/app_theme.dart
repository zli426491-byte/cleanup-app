import 'package:flutter/material.dart';

/// Design System — 清新薄荷風格
class AppTheme {
  // ── Colors ──
  static const Color primary = Color(0xFF167653); // 清晰可讀的薄荷綠
  static const Color primaryLight = Color(0xFFE8F5EE); // 薄荷最淺
  static const Color primaryMuted = Color(0xFF7ECBAB); // 薄荷中間
  static const Color accent = Color(0xFFF0997B); // 珊瑚橘（行動/警示）
  static const Color accentLight = Color(0xFFFFF0EB); // 珊瑚最淺
  static const Color danger = Color(0xFFC7353C); // 紅（錯誤/刪除）
  static const Color dangerLight = Color(0xFFFFEEEF);
  static const Color warning = Color(0xFF89600B); // 琥珀（注意）
  static const Color warningLight = Color(0xFFFFF8E7);
  static const Color success = primary;
  static const Color successLight = Color(0xFFE8F5EE);

  static const Color bg = Color(0xFFF7F7F5); // 全局背景
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE8E8E4); // 卡片邊框
  static const Color divider = Color(0xFFF0F0EC);

  static const Color textTitle = Color(0xFF1A1A1A); // 標題
  static const Color textBody = Color(0xFF3D3D3D); // 正文
  static const Color textSecondary = Color(0xFF62645D); // 次要
  static const Color textMuted = Color(0xFF6D7068); // 提示仍可讀

  // Aliases for backward compat
  static const Color textPrimary = textTitle;

  // ── Spacing ──
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // ── Radius ──
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r50 = 50; // pill

  // ── Text Styles ──
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textTitle,
    letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textTitle,
    letterSpacing: -0.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: textTitle,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textBody,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  static const TextStyle small = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Gradients (minimal use) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF167C57)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, Color(0xFFB72C33)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Kept for backward compat
  static const LinearGradient darkGradient = primaryGradient;
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5A31A), Color(0xFFF0C85C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static BoxShadow softShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
  static BoxShadow colorShadow(Color c) => BoxShadow(
    color: c.withValues(alpha: 0.2),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );

  // ── Theme ──
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textTitle,
      titleTextStyle: heading2,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r16),
        side: const BorderSide(color: border, width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 0.5,
      space: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 60,
      elevation: 0,
      backgroundColor: cardBg,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        );
      }),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: const Color(0xFF111111),
  );
}
