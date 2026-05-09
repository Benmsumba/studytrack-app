import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_spacing.dart';
import 'app_palette.dart';

/// Single source of truth for the StudyTrack design system.
/// Builds Material 3 themes whose component styling automatically
/// resolves through the [AppPalette] theme extension so every screen
/// looks correct in both light and dark modes without per-screen logic.
class AppTheme {
  AppTheme._();

  static ThemeData dark({ColorScheme? dynamicColorScheme}) =>
      _build(AppPalette.dark, dynamicColorScheme);

  static ThemeData light({ColorScheme? dynamicColorScheme}) =>
      _build(AppPalette.light, dynamicColorScheme);

  static ThemeData _build(AppPalette palette, ColorScheme? dynamic) {
    final isDark = palette.isDark;

    final scheme = (dynamic ??
            ColorScheme.fromSeed(
              seedColor: palette.brandPrimary,
              brightness: palette.brightness,
            ))
        .copyWith(
      primary: palette.brandPrimary,
      onPrimary: Colors.white,
      secondary: palette.brandSecondary,
      onSecondary: Colors.white,
      tertiary: palette.brandTertiary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainer: palette.surfaceElevated,
      surfaceContainerHigh: palette.card,
      surfaceContainerHighest: palette.surfaceElevated,
      outline: palette.border,
      outlineVariant: palette.borderSoft,
      error: palette.danger,
      onError: Colors.white,
    );

    final textTheme = _textTheme(palette);

    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.divider,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyleDark()._value
            : const SystemUiOverlayStyleLight()._value,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: palette.borderSoft),
        ),
        margin: EdgeInsets.zero,
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textPrimary,
          backgroundColor: palette.surfaceElevated.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            side: BorderSide(
              color: palette.borderSoft.withValues(alpha: isDark ? 1 : 0.6),
            ),
          ),
          padding: const EdgeInsets.all(10),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: BorderSide(color: palette.borderSoft),
        ),
        actionTextColor: palette.brandSecondary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: _outlineBorder(palette.borderSoft, AppSpacing.fieldRadius),
        enabledBorder:
            _outlineBorder(palette.borderSoft, AppSpacing.fieldRadius),
        focusedBorder: _outlineBorder(
          palette.brandSecondary,
          AppSpacing.fieldRadius,
          width: 1.5,
        ),
        errorBorder: _outlineBorder(palette.danger, AppSpacing.fieldRadius),
        focusedErrorBorder: _outlineBorder(
          palette.danger,
          AppSpacing.fieldRadius,
          width: 1.5,
        ),
        labelStyle: textTheme.labelLarge,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.brandSecondary,
          textStyle: textTheme.labelMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceElevated,
        selectedColor: palette.brandPrimary.withValues(alpha: 0.18),
        disabledColor: palette.surfaceElevated,
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.textPrimary),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: palette.textPrimary),
        side: BorderSide(color: palette.borderSoft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.borderSoft,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: palette.borderSoft),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.brandSecondary,
        linearTrackColor: palette.borderSoft,
        circularTrackColor: palette.borderSoft,
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.brandPrimary,
        unselectedLabelColor: palette.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: palette.brandPrimary, width: 2),
        ),
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.brandPrimary
              : palette.borderSoft,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.brandSecondary,
        inactiveTrackColor: palette.borderSoft,
        thumbColor: palette.brandPrimary,
        overlayColor: palette.brandPrimary.withValues(alpha: 0.18),
        valueIndicatorColor: palette.brandPrimary,
        valueIndicatorTextStyle: textTheme.labelLarge,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.borderSoft),
        ),
        textStyle: textTheme.bodySmall,
        waitDuration: const Duration(milliseconds: 350),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.35),
        width: 300,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
        ),
        titleTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return base.copyWith(extensions: [palette]);
  }

  static OutlineInputBorder _outlineBorder(
    Color color,
    double radius, {
    double width = 1,
  }) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(AppPalette palette) {
    final outfit = GoogleFonts.outfitTextTheme();
    final inter = GoogleFonts.interTextTheme();
    return TextTheme(
      displayLarge: outfit.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: palette.textGlow,
      ),
      displayMedium: outfit.displayMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
        color: palette.textGlow,
      ),
      displaySmall: outfit.displaySmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      headlineLarge: outfit.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.35,
        color: palette.textPrimary,
      ),
      headlineMedium: outfit.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      headlineSmall: outfit.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: palette.textPrimary,
      ),
      titleLarge: outfit.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: palette.textSecondary,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.55,
        color: palette.textPrimary,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: palette.textPrimary,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.45,
        color: palette.textSecondary,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: palette.textPrimary,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: palette.textPrimary,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: palette.textMuted,
      ),
    );
  }
}

// ── Status-bar overlay helpers (for AppBar systemOverlayStyle) ──────────────
class SystemUiOverlayStyleDark {
  const SystemUiOverlayStyleDark();
  SystemUiOverlayStyle get _value => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      );
}

class SystemUiOverlayStyleLight {
  const SystemUiOverlayStyleLight();
  SystemUiOverlayStyle get _value => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      );
}
