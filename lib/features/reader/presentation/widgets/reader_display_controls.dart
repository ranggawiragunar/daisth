import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../view_models/reader_view_model.dart';

Future<void> showReaderDisplayControls(
  BuildContext context,
  ReaderViewModel viewModel,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _ReaderControlsSheet(viewModel: viewModel),
);

class _ReaderControlsSheet extends StatelessWidget {
  const _ReaderControlsSheet({required this.viewModel});

  final ReaderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) => Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DaisthRadius.xLarge + 4),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DaisthRadius.xLarge + 4),
            ),
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: EdgeInsets.fromLTRB(
            DaisthSpacing.xl,
            DaisthSpacing.md,
            DaisthSpacing.xl,
            DaisthSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(DaisthRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: DaisthSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Tampilan Bacaan',
                        en: 'Reading display',
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: DaisthLocalizations.text(
                      context,
                      id: 'Tutup',
                      en: 'Close',
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.x),
                  ),
                ],
              ),
              const SizedBox(height: DaisthSpacing.md),
              SwitchListTile.adaptive(
                key: const ValueKey('reader-transliteration-toggle'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DaisthLocalizations.text(
                    context,
                    id: 'Transliterasi',
                    en: 'Transliteration',
                  ),
                ),
                value: viewModel.transliterationVisible,
                onChanged: viewModel.setTransliterationVisible,
              ),
              SwitchListTile.adaptive(
                key: const ValueKey('reader-translation-toggle'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DaisthLocalizations.text(
                    context,
                    id: 'Terjemahan',
                    en: 'Translation',
                  ),
                ),
                value: viewModel.translationVisible,
                onChanged: viewModel.setTranslationVisible,
              ),
              const SizedBox(height: DaisthSpacing.sm),
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Ukuran teks',
                  en: 'Text size',
                ),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: DaisthSpacing.sm),
              Wrap(
                spacing: DaisthSpacing.sm,
                runSpacing: DaisthSpacing.sm,
                children: [
                  for (final scale in ReaderViewModel.supportedTextScales)
                    ChoiceChip(
                      key: ValueKey('reader-scale-${(scale * 100).round()}'),
                      label: Text('${(scale * 100).round()}%'),
                      selected: viewModel.textScale == scale,
                      onSelected: (_) => viewModel.setTextScale(scale),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
