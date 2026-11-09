import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the light and dark [ThemeData] from [AppColors].
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      secondary: colors.brandDeep,
      onSecondary: colors.onBrand,
      error: colors.danger,
      onError: colors.onBrand,
      surface: colors.surface,
      onSurface: colors.ink,
      outline: colors.line,
    );
    final borderShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.ground,
      textTheme: AppTextStyles.textTheme(colors.ink, colors.body),
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.ground,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.heading.copyWith(color: colors.ink),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButton),
          shape: borderShape,
          textStyle: AppTextStyles.button,
          backgroundColor: colors.brand,
          foregroundColor: colors.onBrand,
          disabledBackgroundColor: colors.disabled,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.button),
          shape: borderShape,
          textStyle: AppTextStyles.button,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.line, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        border: _fieldBorder(colors.line),
        enabledBorder: _fieldBorder(colors.line),
        focusedBorder: _fieldBorder(colors.brand),
        errorBorder: _fieldBorder(colors.danger),
        focusedErrorBorder: _fieldBorder(colors.danger),
        errorStyle: AppTextStyles.caption.copyWith(color: colors.danger),
      ),
      dividerTheme: DividerThemeData(
        color: colors.sand,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
