import 'package:flutter/material.dart';

import '../theme/istiqam_theme_extension.dart';
import '../tokens/istiqam_spacing.dart';

class IstiqamEmptyState extends StatelessWidget {
  const IstiqamEmptyState({
    required this.imageAsset,
    required this.title,
    required this.description,
    super.key,
  });

  final String imageAsset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<IstiqamThemeExtension>()!;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(IstiqamSpacing.section),
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
                    padding: const EdgeInsets.all(IstiqamSpacing.lg),
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
                const SizedBox(height: IstiqamSpacing.xxl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: IstiqamSpacing.sm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
