import 'package:flutter/material.dart';

import '../tokens/daisth_colors.dart';
import '../tokens/daisth_radius.dart';
import '../tokens/daisth_typography.dart';
import 'daisth_notice_palette.dart';
import 'daisth_theme_extension.dart';

abstract final class DaisthTheme {
  static final light = _buildLight();
  static final dark = _buildDark();

  static ThemeData _buildLight() {
    const scheme = ColorScheme.light(
      primary: DaisthColors.primary700,
      onPrimary: Colors.white,
      primaryContainer: DaisthColors.primary100,
      onPrimaryContainer: DaisthColors.primary900,
      secondary: DaisthColors.accent700,
      onSecondary: Colors.white,
      secondaryContainer: DaisthColors.accent100,
      onSecondaryContainer: DaisthColors.accent700,
      error: Color(0xFF9B5145),
      onError: Colors.white,
      surface: DaisthColors.surface,
      onSurface: DaisthColors.textPrimary,
      onSurfaceVariant: DaisthColors.textSecondary,
      outline: DaisthColors.border,
      outlineVariant: DaisthColors.divider,
    );
    return _base(
      scheme,
      DaisthColors.background,
      DaisthThemeExtension.light,
      DaisthNoticePalette.light,
    );
  }

  static ThemeData _buildDark() {
    const scheme = ColorScheme.dark(
      primary: DaisthColors.darkPrimary,
      onPrimary: DaisthColors.darkBackground,
      primaryContainer: DaisthColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFD9E9E1),
      secondary: DaisthColors.darkAccent,
      onSecondary: DaisthColors.darkBackground,
      secondaryContainer: Color(0xFF49392D),
      onSecondaryContainer: Color(0xFFF1E2D4),
      error: Color(0xFFE0A197),
      onError: Color(0xFF3E1713),
      surface: DaisthColors.darkSurface,
      onSurface: DaisthColors.darkTextPrimary,
      onSurfaceVariant: DaisthColors.darkTextSecondary,
      outline: DaisthColors.darkBorder,
      outlineVariant: DaisthColors.darkDivider,
    );
    return _base(
      scheme,
      DaisthColors.darkBackground,
      DaisthThemeExtension.dark,
      DaisthNoticePalette.dark,
    );
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color scaffoldBackground,
    DaisthThemeExtension extension,
    DaisthNoticePalette noticePalette,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: DaisthTypography.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: [extension, noticePalette],
    );
    return base.copyWith(
      dividerColor: extension.divider,
      splashColor: scheme.primary.withValues(alpha: 0.06),
      highlightColor: scheme.primary.withValues(alpha: 0.04),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant;
          return DaisthTypography.labelSmall.copyWith(color: color);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DaisthRadius.large),
          side: BorderSide(color: extension.border),
        ),
      ),
    );
  }
}
