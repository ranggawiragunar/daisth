import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/localization/daisth_terminology.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../domain/models/routine_definition.dart';
import '../domain/models/routine_origin.dart';
import '../domain/models/routine_schedule.dart';
import '../domain/repositories/routine_record_repository.dart';
import '../domain/repositories/routine_repository.dart';
import 'view_models/routine_management_view_model.dart';
import '../../../app/router/route_paths.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({
    required this.routineRepository,
    required this.routineRecordRepository,
    required this.noticeController,
    this.bottomContentPadding = 0,
    super.key,
  });

  final RoutineRepository routineRepository;
  final RoutineRecordRepository routineRecordRepository;
  final DaisthNoticeController noticeController;
  final double bottomContentPadding;

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  late final RoutineManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RoutineManagementViewModel(widget.routineRepository)
      ..addListener(_changed);
    unawaited(_viewModel.initialize());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _createRoutine() async {
    final saved = await context.push<bool>(RoutePaths.routineNew);
    if (saved == true) await _viewModel.refresh();
  }

  Future<void> _editCustom(RoutineDefinition routine) async {
    final saved = await context.push<bool>(RoutePaths.routineEdit(routine.id));
    if (saved == true) await _viewModel.refresh();
  }

  Future<void> _editDefault(RoutineDefinition routine) async {
    final saved = await context.push<bool>(RoutePaths.routineEdit(routine.id));
    if (saved == true) await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routines = _viewModel.routines;
    final defaults = routines
        .where((item) => item.origin == RoutineOrigin.defaultRoutine)
        .toList();
    final custom = routines
        .where((item) => item.origin == RoutineOrigin.custom)
        .toList();
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DaisthSpacing.screenHorizontal,
              DaisthSpacing.lg,
              DaisthSpacing.screenHorizontal,
              widget.bottomContentPadding,
            ),
            children: [
              Text(
                DaisthLocalizations.text(
                  context,
                  id: 'Rutinitas',
                  en: 'Routines',
                ),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: DaisthSpacing.xl),
              _SectionTitle(
                title: DaisthLocalizations.text(
                  context,
                  id: 'Bawaan',
                  en: 'Default',
                ),
              ),
              const SizedBox(height: DaisthSpacing.sm),
              DaisthSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < defaults.length; i++) ...[
                      _RoutineManagerRow(
                        definition: defaults[i],
                        onTap: () => _editDefault(defaults[i]),
                      ),
                      if (i != defaults.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DaisthSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _SectionTitle(
                      title: DaisthLocalizations.text(
                        context,
                        id: 'Rutinitas Saya',
                        en: 'My Routines',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _createRoutine,
                    icon: Icon(PhosphorIconsRegular.plus, size: 18),
                    label: Text(
                      DaisthLocalizations.text(
                        context,
                        id: 'Tambah Rutinitas',
                        en: 'Add Routine',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DaisthSpacing.sm),
              if (custom.isEmpty)
                DaisthSurface(
                  child: Padding(
                    padding: const EdgeInsets.all(DaisthSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Belum ada rutinitas khusus.',
                            en: 'No custom routines yet.',
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: DaisthSpacing.xs),
                        Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Buat rutinitas untuk hal yang ingin kamu jaga konsistensinya.',
                            en: "Create one for something you'd like to keep consistent.",
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DaisthSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < custom.length; i++) ...[
                        _RoutineManagerRow(
                          definition: custom[i],
                          onTap: () => _editCustom(custom[i]),
                        ),
                        if (i != custom.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _RoutineManagerRow extends StatelessWidget {
  const _RoutineManagerRow({required this.definition, required this.onTap});
  final RoutineDefinition definition;
  final VoidCallback onTap;

  String _scheduleLabel(BuildContext context) => switch (definition.schedule) {
    FixedRoutineSchedule(:final value) => _formatMinutes(value),
    PrayerRoutineSchedule() => DaisthLocalizations.text(
      context,
      id: 'Waktu salat',
      en: 'Prayer time',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(
          _localizedDefinitionTitle(context, definition),
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          '${_scheduleLabel(context)}${definition.reminderEnabled ? ' · ${DaisthLocalizations.text(context, id: 'Pengingat aktif', en: 'Reminder on')}' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              definition.isEnabled ? 'On' : 'Off',
              style: theme.textTheme.labelSmall?.copyWith(
                color: definition.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(PhosphorIconsRegular.caretRight, size: 16),
          ],
        ),
      ),
    );
  }
}

String _localizedDefinitionTitle(BuildContext context, RoutineDefinition item) {
  final localized = DaisthTerminology.routineTitle(
    item.id,
    Localizations.localeOf(context),
  );
  return localized.isEmpty ? item.title : localized;
}

String _formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
