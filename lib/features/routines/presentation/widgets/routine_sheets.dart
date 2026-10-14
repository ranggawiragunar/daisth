import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_button.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/localization/daisth_localizations.dart';
import '../../domain/models/routine_step.dart';

class NotTodaySelection {
  const NotTodaySelection(this.reason);

  final String? reason;
}

Future<NotTodaySelection?> showNotTodaySheet(BuildContext context) {
  const reasons = [
    'Ketiduran',
    'Tidak sempat',
    'Bepergian',
    'Kondisi fisik',
    'Lainnya',
  ];
  return showModalBottomSheet<NotTodaySelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      String? selectedReason;
      return StatefulBuilder(
        builder: (context, setSheetState) => _RoutineSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(DaisthRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: DaisthSpacing.xl),
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Tidak dilakukan hari ini?',
                  en: 'Not today?',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: DaisthSpacing.xs),
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Kamu bisa menambahkan alasan jika ingin. Ini opsional.',
                  en: 'You can add a reason if you like. This is optional.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DaisthSpacing.lg),
              Wrap(
                spacing: DaisthSpacing.sm,
                runSpacing: DaisthSpacing.sm,
                children: [
                  for (final reason in reasons)
                    ChoiceChip(
                      label: Text(_localizedReason(context, reason)),
                      selected: selectedReason == reason,
                      onSelected: (_) => setSheetState(
                        () => selectedReason = selectedReason == reason
                            ? null
                            : reason,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DaisthSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: DaisthButton(
                  label: DaisthLocalizations.text(
                    context,
                    id: 'Simpan',
                    en: 'Save',
                  ),
                  onPressed: () => Navigator.of(
                    sheetContext,
                  ).pop(NotTodaySelection(selectedReason)),
                ),
              ),
              const SizedBox(height: DaisthSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(
                  sheetContext,
                ).pop(const NotTodaySelection(null)),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: Text(
                  DaisthLocalizations.text(
                    context,
                    id: 'Lewati alasan',
                    en: 'Skip reason',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _localizedReason(BuildContext context, String reason) =>
    switch (reason) {
      'Ketiduran' => DaisthLocalizations.text(
        context,
        id: 'Ketiduran',
        en: 'Overslept',
      ),
      'Tidak sempat' => DaisthLocalizations.text(
        context,
        id: 'Tidak sempat',
        en: 'Ran out of time',
      ),
      'Bepergian' => DaisthLocalizations.text(
        context,
        id: 'Bepergian',
        en: 'Travelling',
      ),
      'Kondisi fisik' => DaisthLocalizations.text(
        context,
        id: 'Kondisi fisik',
        en: 'Physical condition',
      ),
      'Lainnya' => DaisthLocalizations.text(
        context,
        id: 'Lainnya',
        en: 'Other',
      ),
      _ => reason,
    };

Future<void> showRoutineStepSheet({
  required BuildContext context,
  required RoutineStep step,
  required VoidCallback onToggle,
  required VoidCallback onOpenReading,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RoutineSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(DaisthRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: DaisthSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  step.guidanceTitle ?? step.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: DaisthLocalizations.text(
                  context,
                  id: 'Tutup',
                  en: 'Close',
                ),
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(PhosphorIconsRegular.x),
              ),
            ],
          ),
          Text(step.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: DaisthSpacing.xl),
          Text(
            DaisthLocalizations.text(context, id: 'Panduan', en: 'Guidance'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: DaisthSpacing.sm),
          Text(
            step.guidanceTitle ?? 'Panduan ${step.title}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DaisthSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: DaisthButton(
              label: step.completed
                  ? DaisthLocalizations.text(
                      context,
                      id: 'Tandai Belum Selesai',
                      en: 'Mark as Not Done',
                    )
                  : DaisthLocalizations.text(
                      context,
                      id: 'Tandai ${step.title} Selesai',
                      en: 'Mark ${step.title} Done',
                    ),
              onPressed: () {
                onToggle();
                Navigator.of(sheetContext).pop();
              },
            ),
          ),
          const SizedBox(height: DaisthSpacing.xs),
          TextButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              onOpenReading();
            },
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            icon: const Icon(PhosphorIconsRegular.bookOpenText, size: 18),
            label: Text(
              DaisthLocalizations.text(
                context,
                id: 'Buka Bacaan',
                en: 'Open Reading',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoutineSheetFrame extends StatelessWidget {
  const _RoutineSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DaisthRadius.xLarge + 4),
          ),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            DaisthSpacing.xl,
            DaisthSpacing.md,
            DaisthSpacing.xl,
            DaisthSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}
