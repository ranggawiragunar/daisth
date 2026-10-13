import 'package:flutter/material.dart';

import '../theme/daisth_theme_extension.dart';
import '../tokens/daisth_spacing.dart';

class DaisthEmptyState extends StatelessWidget {
  const DaisthEmptyState({
    required this.imageAsset,
    required this.title,
    required this.description,
    this.footer,
    this.bottomContentPadding = DaisthSpacing.section,
    super.key,
  });

  final String imageAsset;
  final String title;
  final String description;
  final Widget? footer;
  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<DaisthThemeExtension>()!;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            DaisthSpacing.section,
            DaisthSpacing.section,
            DaisthSpacing.section,
            bottomContentPadding,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: extension.artMatte,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DaisthSpacing.lg),
                    child: Image.asset(
                      imageAsset,
                      width: 220,
                      height: 190,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      semanticLabel: title,
                    ),
                  ),
                ),
                const SizedBox(height: DaisthSpacing.xxl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: DaisthSpacing.sm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: DaisthSpacing.section),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
