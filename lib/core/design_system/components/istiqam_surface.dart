import 'package:flutter/material.dart';

import '../theme/istiqam_theme_extension.dart';
import '../tokens/istiqam_radius.dart';

enum IstiqamSurfaceStyle { standard, softPrimary, warm }

class IstiqamSurface extends StatelessWidget {
  const IstiqamSurface({
    required this.child,
    this.style = IstiqamSurfaceStyle.standard,
    this.padding = const EdgeInsets.all(16),
    this.radius = IstiqamRadius.large,
    this.border = true,
    super.key,
  });

  final Widget child;
  final IstiqamSurfaceStyle style;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    final background = switch (style) {
      IstiqamSurfaceStyle.standard => theme.colorScheme.surface,
      IstiqamSurfaceStyle.softPrimary => extension.softSurface,
      IstiqamSurfaceStyle.warm => extension.warmSurface,
    };
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: extension.border) : null,
      ),
      child: child,
    );
  }
}
