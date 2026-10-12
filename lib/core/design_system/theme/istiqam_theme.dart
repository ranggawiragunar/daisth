import 'package:flutter/material.dart';

import '../tokens/istiqam_colors.dart';
import '../tokens/istiqam_radius.dart';
import '../tokens/istiqam_typography.dart';
import 'istiqam_notice_palette.dart';
import 'istiqam_theme_extension.dart';

abstract final class IstiqamTheme {
  static final light = _buildLight();
  static final dark = _buildDark();

  static ThemeData _buildLight() {
    const scheme = ColorScheme.light(
      primary: IstiqamColors.primary700,
      onPrimary: Colors.white,
      primaryContainer: IstiqamColors.primary100,
      onPrimaryContainer: IstiqamColors.primary900,
      secondary: IstiqamColors.accent700,
      onSecondary: Colors.white,
      secondaryContainer: IstiqamColors.accent100,
      onSecondaryContainer: IstiqamColors.accent700,
      error: Color(0xFF9B5145),
      onError: Colors.white,
      surface: IstiqamColors.surface,
      onSurface: IstiqamColors.textPrimary,
      onSurfaceVariant: IstiqamColors.textSecondary,
      outline: IstiqamColors.border,
      outlineVariant: IstiqamColors.divider,
    );
    return _base(
      scheme,
      IstiqamColors.background,
      IstiqamThemeExtension.light,
      IstiqamNoticePalette.light,
    );
  }

  static ThemeData _buildDark() {
    const scheme = ColorScheme.dark(
      primary: IstiqamColors.darkPrimary,
      onPrimary: IstiqamColors.darkBackground,
      primaryContainer: IstiqamColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFD9E9E1),
      secondary: IstiqamColors.darkAccent,
      onSecondary: IstiqamColors.darkBackground,
      secondaryContainer: Color(0xFF49392D),
      onSecondaryContainer: Color(0xFFF1E2D4),
      error: Color(0xFFE0A197),
      onError: Color(0xFF3E1713),
      surface: IstiqamColors.darkSurface,
      onSurface: IstiqamColors.darkTextPrimary,
      onSurfaceVariant: IstiqamColors.darkTextSecondary,
      outline: IstiqamColors.darkBorder,
      outlineVariant: IstiqamColors.darkDivider,
    );
    return _base(
      scheme,
      IstiqamColors.darkBackground,
      IstiqamThemeExtension.dark,
      IstiqamNoticePalette.dark,
    );
  }

  static ThemeData _base(
    ColorScheme scheme,
    Color scaffoldBackground,
    IstiqamThemeExtension extension,
    IstiqamNoticePalette noticePalette,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: IstiqamTypography.textTheme.apply(
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
          return IstiqamTypography.labelSmall.copyWith(color: color);
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
          borderRadius: BorderRadius.circular(IstiqamRadius.large),
          side: BorderSide(color: extension.border),
        ),
      ),
    );
  }
}
