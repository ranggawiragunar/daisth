import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/design_system/components/daisth_button.dart';
import '../../../../core/design_system/tokens/daisth_radius.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
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
                'Tidak dilakukan hari ini?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: DaisthSpacing.xs),
              Text(
                'Kamu bisa menambahkan alasan jika ingin. Ini opsional.',
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
                      label: Text(reason),
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
                  label: 'Simpan',
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
                child: const Text('Lewati alasan'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

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
                tooltip: 'Close',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(PhosphorIconsRegular.x),
              ),
            ],
          ),
          Text(step.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: DaisthSpacing.xl),
          Text('Guidance', style: Theme.of(context).textTheme.titleSmall),
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
                  ? 'Mark as Not Done'
                  : 'Mark ${step.title} Done',
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
            label: const Text('Open Reading'),
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
