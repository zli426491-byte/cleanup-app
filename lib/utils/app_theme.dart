import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design System — iOS 系統藍、白底、淡藍卡片（2026-09-29 UI v2）
class AppTheme {
  // ── Colors ──
  static const Color primary = Color(0xFF0068DB); // 系統藍（加深至 AA 對比）：主按鈕、強調數字
  static const Color primaryDark = Color(0xFF0056B8); // 按下／白字對比
  static const Color primaryLight = Color(0xFFEEF3FD); // 淡藍卡片底
  static const Color primaryMuted = Color(0xFFBFD7FF); // 空分類插圖
  static const Color accent = Color(0xFFFF9F0A); // 橘（星等、提示）
  static const Color accentLight = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFC9281E); // 刪除勾選、容量警示（AA 對比）
  static const Color dangerLight = Color(0xFFFFEBEA);
  static const Color warning = Color(0xFF9A5B00); // 淺底上可讀的琥珀
  static const Color warningLight = Color(0xFFFFF6E5);
  static const Color success = Color(0xFF1FA84F); // 保留、試用已啟用
  static const Color successLight = Color(0xFFE6F7EC);
  // Small green text on light cards (≥4.5:1 on #EEF3FD).
  static const Color successText = Color(0xFF137A3A);

  static const Color bg = Colors.white; // 全局背景
  static const Color cardBg = primaryLight; // 卡片（無陰影、無邊框）
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE3E8F2);
  static const Color divider = Color(0xFFEDF0F5);

  static const Color textTitle = Color(0xFF0B0B12); // 標題
  static const Color textBody = Color(0xFF1F2330); // 正文
  static const Color textSecondary = Color(0xFF5F6675); // 次要
  static const Color textMuted = Color(0xFF646B7A); // 提示仍可讀（AA 對比）

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
  /// iOS Large Title：分頁與清單頁的靠左大標題。
  static const TextStyle largeTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textTitle,
    letterSpacing: -0.8,
    height: 1.1,
  );
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textTitle,
    letterSpacing: -0.6,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: textTitle,
    letterSpacing: -0.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textTitle,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textBody,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.2,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.4,
  );

  // ── Shadows ── 卡片不再使用陰影；保留 API 給舊畫面。
  static List<BoxShadow> get cardShadow => const [];

  // ── Gradients (minimal use) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF0056C0), Color(0xFF0068DB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, danger],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Kept for backward compat
  static const LinearGradient darkGradient = primaryGradient;
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB340), Color(0xFFFFCC66)],
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
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      error: danger,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textTitle,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textTitle,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 0.5,
      space: 0,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      height: 60,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return const TextStyle(
          fontSize: 11,
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
