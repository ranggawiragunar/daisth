import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../domain/models/reader_section.dart';
import 'reader_typography.dart';

class ReaderTextSection extends StatelessWidget {
  const ReaderTextSection({
    required this.section,
    required this.textScale,
    required this.showTransliteration,
    required this.showTranslation,
    required this.languageCode,
    super.key,
  });

  final ReaderSection section;
  final double textScale;
  final bool showTransliteration;
  final bool showTranslation;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final english = languageCode.toLowerCase() == 'en';
    final hasArabic = section.arabic?.isNotEmpty ?? false;
    final heading = section.headingFor(languageCode);
    final translation = section.translationFor(languageCode);
    final sourceLabel = section.sourceLabelFor(languageCode);
    final note = section.noteFor(languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null) ...[
          Text(heading, style: theme.textTheme.titleSmall),
          const SizedBox(height: DaisthSpacing.lg),
        ],
        if (section.showFieldLabels && hasArabic) ...[
          _ReaderFieldLabel(label: english ? 'Arabic' : 'Arab'),
          const SizedBox(height: DaisthSpacing.xs),
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
          const SizedBox(height: DaisthSpacing.xl),
          if (section.showFieldLabels) ...[
            _ReaderFieldLabel(
              label: english ? 'Transliteration' : 'Transliterasi',
            ),
            const SizedBox(height: DaisthSpacing.xs),
          ],
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
        if (showTranslation && translation != null) ...[
          const SizedBox(height: DaisthSpacing.lg),
          if (section.showFieldLabels) ...[
            _ReaderFieldLabel(label: english ? 'Meaning' : 'Makna'),
            const SizedBox(height: DaisthSpacing.xs),
          ],
          SelectableText(
            translation,
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
        if (sourceLabel != null || note != null) ...[
          const SizedBox(height: DaisthSpacing.md),
          if (section.showFieldLabels) ...[
            _ReaderFieldLabel(label: english ? 'Source' : 'Sumber'),
            const SizedBox(height: DaisthSpacing.xs),
          ],
          if (sourceLabel != null)
            Text(
              sourceLabel,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (note != null) ...[
            if (sourceLabel != null) const SizedBox(height: DaisthSpacing.xxs),
            SelectableText(
              note,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                height: 1.6,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ReaderFieldLabel extends StatelessWidget {
  const _ReaderFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
  );
}
