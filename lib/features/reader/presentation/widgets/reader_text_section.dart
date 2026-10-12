import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/istiqam_spacing.dart';
import '../../domain/models/reader_section.dart';
import 'reader_typography.dart';

class ReaderTextSection extends StatelessWidget {
  const ReaderTextSection({
    required this.section,
    required this.textScale,
    required this.showTransliteration,
    required this.showTranslation,
    super.key,
  });

  final ReaderSection section;
  final double textScale;
  final bool showTransliteration;
  final bool showTranslation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final hasArabic = section.arabic?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.heading != null) ...[
          Text(section.heading!, style: theme.textTheme.titleSmall),
          const SizedBox(height: IstiqamSpacing.lg),
        ],
        if (hasArabic)
          SelectableText(
            section.arabic!,
            key: const ValueKey('reader-arabic'),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: ReaderTypography.arabic(context, textScale),
          ),
        if (showTransliteration && section.transliteration != null) ...[
          const SizedBox(height: IstiqamSpacing.xl),
          SelectableText(
            section.transliteration!,
            key: const ValueKey('reader-transliteration'),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * textScale,
              height: 1.65,
              color: secondaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (showTranslation && section.translation != null) ...[
          const SizedBox(height: IstiqamSpacing.lg),
          SelectableText(
            section.translation!,
            key: const ValueKey('reader-translation'),
            textDirection: TextDirection.ltr,
            textAlign: hasArabic ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * textScale,
              height: 1.7,
              color: textColor,
            ),
          ),
        ],
        if (section.note != null) ...[
          const SizedBox(height: IstiqamSpacing.md),
          SelectableText(
            section.note!,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}
