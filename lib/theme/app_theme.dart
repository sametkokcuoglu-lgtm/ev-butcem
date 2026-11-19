import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Gelir, gider ve hero kartı gibi anlamsal renkler.
/// Açık ve koyu temada ayrı tonlar kullanılır; kontrast buna göre ayarlanır.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color income;
  final Color expense;
  final Color warning;
  final Color heroStart;
  final Color heroMid;
  final Color heroEnd;
  final Color line;

  const FinanceColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.heroStart,
    required this.heroMid,
    required this.heroEnd,
    required this.line,
  });

  static FinanceColors of(BuildContext context) =>
      Theme.of(context).extension<FinanceColors>() ?? light;

  static const light = FinanceColors(
    income: Color(0xFF047857),
    expense: Color(0xFFDC2626),
    warning: Color(0xFFB45309),
    heroStart: Color(0xFF071A3A),
    heroMid: Color(0xFF143F9A),
    heroEnd: Color(0xFF2F6BFF),
    line: Color(0xFFE6EBF3),
  );

  static const dark = FinanceColors(
    income: Color(0xFF34D399),
    expense: Color(0xFFFB7185),
    warning: Color(0xFFFBBF24),
    heroStart: Color(0xFF071A3A),
    heroMid: Color(0xFF1D4ED8),
    heroEnd: Color(0xFF3B82F6),
    line: Color(0xFF243044),
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? heroStart,
    Color? heroMid,
    Color? heroEnd,
    Color? line,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      heroStart: heroStart ?? this.heroStart,
      heroMid: heroMid ?? this.heroMid,
      heroEnd: heroEnd ?? this.heroEnd,
      line: line ?? this.line,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroMid: Color.lerp(heroMid, other.heroMid, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  /// Mevcut çağrılar (silme düğmesi vb.) için sabit marka renkleri.
  static const Color primaryColor = Color(0xFF1D4ED8);
  static const Color incomeColor = Color(0xFF059669);
  static const Color expenseColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);

  static const Color _lightCanvas = Color(0xFFF2F5FA);
  static const Color _lightInk = Color(0xFF0F172A);
  static const Color _lightMuted = Color(0xFF64748B);
  static const Color _darkCanvas = Color(0xFF070D18);
  static const Color _darkCard = Color(0xFF121A2B);
  static const Color _darkInk = Color(0xFFF8FAFC);
  static const Color _darkMuted = Color(0xFF94A3B8);

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        canvas: _lightCanvas,
        card: Colors.white,
        ink: _lightInk,
        muted: _lightMuted,
        finance: FinanceColors.light,
        primary: primaryColor,
        onPrimary: Colors.white,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        canvas: _darkCanvas,
        card: _darkCard,
        ink: _darkInk,
        muted: _darkMuted,
        finance: FinanceColors.dark,
        primary: const Color(0xFF3B82F6),
        onPrimary: Colors.white,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color card,
    required Color ink,
    required Color muted,
    required FinanceColors finance,
    required Color primary,
    required Color onPrimary,
  }) {
    final base = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
    final scheme = base.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: card,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: finance.line,
      error: finance.expense,
    );
    final text = _textTheme(brightness, ink);
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: finance.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: text,
      extensions: [finance],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 20, letterSpacing: -0.4),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      dividerTheme: DividerThemeData(color: finance.line, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        side: BorderSide.none,
        labelStyle: text.labelMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        extendedTextStyle: text.labelLarge?.copyWith(color: onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: brightness == Brightness.light ? Colors.white : const Color(0xFF0C1424),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontSize: 11,
            height: 1.1,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 22, color: selected ? primary : muted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? Colors.white : const Color(0xFF182236),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: text.bodyMedium?.copyWith(color: muted),
        hintStyle: text.bodyMedium?.copyWith(color: muted.withValues(alpha: 0.8)),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: primary, width: 1.6)),
        errorBorder: border.copyWith(borderSide: BorderSide(color: finance.expense)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: finance.expense, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          textStyle: WidgetStatePropertyAll(text.labelLarge?.copyWith(fontSize: 13)),
          side: WidgetStatePropertyAll(BorderSide(color: finance.line)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall?.copyWith(color: muted),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness, Color ink) {
    final base = ThemeData(brightness: brightness, fontFamily: fontFamily).textTheme;
    return base
        .copyWith(
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.35),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.35),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
        )
        .apply(bodyColor: ink, displayColor: ink, fontFamily: fontFamily);
  }
}
