import 'package:flutter/material.dart';

import '../theme/daisth_theme_extension.dart';
import '../tokens/daisth_radius.dart';

enum DaisthSurfaceStyle { standard, softPrimary, warm }

class DaisthSurface extends StatelessWidget {
  const DaisthSurface({required this.child, this.style = DaisthSurfaceStyle.standard, this.padding = const EdgeInsets.all(16), this.radius = DaisthRadius.large, this.border = true, super.key});

  final Widget child;
  final DaisthSurfaceStyle style;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    final background = switch (style) {
      DaisthSurfaceStyle.standard => theme.colorScheme.surface,
      DaisthSurfaceStyle.softPrimary => extension.softSurface,
      DaisthSurfaceStyle.warm => extension.warmSurface,
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
