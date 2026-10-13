import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/components/daisth_button.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../data/catalog/default_routine_template_catalog.dart';
import '../domain/models/routine_definition.dart';
import '../domain/models/routine_origin.dart';
import '../domain/models/routine_priority.dart';
import '../domain/models/routine_schedule.dart';
import '../domain/models/routine_step_definition.dart';
import '../domain/repositories/routine_record_repository.dart';
import '../domain/repositories/routine_repository.dart';
import '../domain/use_cases/reset_default_routine_use_case.dart';
import '../domain/use_cases/save_custom_routine_use_case.dart';
import 'view_models/routine_management_view_model.dart';

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
    final now = DateTime.now().toUtc();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => _CustomRoutineEditor(
        repository: widget.routineRepository,
        recordRepository: widget.routineRecordRepository,
        noticeController: widget.noticeController,
        initial: RoutineDefinition(
          id: createCustomRoutineId(now: now),
          origin: RoutineOrigin.custom,
          title: '',
          description: null,
          isEnabled: true,
          isArchived: false,
          schedule: RoutineSchedule.fixed(8 * 60),
          reminderEnabled: true,
          priority: RoutinePriority.medium,
          sortOrder: 100,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    if (saved == true) await _viewModel.refresh();
  }

  Future<void> _editCustom(RoutineDefinition routine) async {
    final steps = await widget.routineRepository.getSteps(routine.id);
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => _CustomRoutineEditor(
        repository: widget.routineRepository,
        recordRepository: widget.routineRecordRepository,
        noticeController: widget.noticeController,
        initial: routine,
        initialSteps: steps,
      ),
    );
    if (saved == true) await _viewModel.refresh();
  }

  Future<void> _editDefault(RoutineDefinition routine) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _DefaultRoutineEditor(
        repository: widget.routineRepository,
        initial: routine,
        onFailure: (message) => _showError(message),
      ),
    );
    if (saved == true) await _viewModel.refresh();
  }

  void _showError(String message) => widget.noticeController.show(
    context,
    type: DaisthNoticeType.error,
    title: message,
  );

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
              Text('Routines', style: theme.textTheme.headlineSmall),
              const SizedBox(height: DaisthSpacing.xl),
              _SectionTitle(title: 'Default'),
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
                  const Expanded(child: _SectionTitle(title: 'My Routines')),
                  TextButton.icon(
                    onPressed: _createRoutine,
                    icon: Icon(PhosphorIconsRegular.plus, size: 18),
                    label: const Text('Add Routine'),
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
                          'No custom routines yet.',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: DaisthSpacing.xs),
                        Text(
                          "Create one for something you'd like to keep consistent.",
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

  String get _scheduleLabel => switch (definition.schedule) {
    FixedRoutineSchedule(:final value) => _formatMinutes(value),
    PrayerRoutineSchedule() => 'Prayer time',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(definition.title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '$_scheduleLabel${definition.reminderEnabled ? ' · Reminder on' : ''}',
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

class _DefaultRoutineEditor extends StatefulWidget {
  const _DefaultRoutineEditor({
    required this.repository,
    required this.initial,
    required this.onFailure,
  });
  final RoutineRepository repository;
  final RoutineDefinition initial;
  final ValueChanged<String> onFailure;
  @override
  State<_DefaultRoutineEditor> createState() => _DefaultRoutineEditorState();
}

class _DefaultRoutineEditorState extends State<_DefaultRoutineEditor> {
  late RoutineDefinition _draft = widget.initial;
  bool _saving = false;
  bool _allowPop = false;

  bool get _dirty =>
      _draft.isEnabled != widget.initial.isEnabled ||
      _draft.reminderEnabled != widget.initial.reminderEnabled ||
      _draft.schedule.kind != widget.initial.schedule.kind ||
      _draft.schedule.minutesAfterMidnight !=
          widget.initial.schedule.minutesAfterMidnight;

  bool get _timeEditable =>
      const {'sholat-malam', 'dhuha', 'penutup-hari'}.contains(_draft.id);

  Future<void> _pickTime() async {
    final minutes = _draft.schedule.minutesAfterMidnight ?? 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        schedule: RoutineSchedule.fixed(picked.hour * 60 + picked.minute),
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.saveRoutine(
        _draft.copyWith(updatedAt: DateTime.now().toUtc()),
      );
      if (mounted) {
        _allowPop = true;
        Navigator.pop(context, true);
      }
    } catch (_) {
      widget.onFailure('Perubahan rutinitas belum dapat disimpan.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => _ConfirmSheet(
        title: 'Reset this routine?',
        message:
            "Its schedule and reminder settings will return to the Daisth default. Daily records won't be removed.",
        confirmLabel: 'Reset to Default',
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ResetDefaultRoutineUseCase(
        repository: widget.repository,
        templates: DefaultRoutineTemplateCatalog.definitions,
      )(widget.initial.id);
      if (mounted) {
        _allowPop = true;
        Navigator.pop(context, true);
      }
    } catch (_) {
      widget.onFailure('Rutinitas belum dapat direset.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onPop(bool didPop) async {
    if (didPop || !_dirty || _allowPop || _saving) return;
    final discard = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _ConfirmSheet(
        title: 'Discard changes?',
        message: 'Your unsaved routine changes will be lost.',
        confirmLabel: 'Discard Changes',
      ),
    );
    if (discard == true && mounted) {
      _allowPop = true;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _draft.schedule.minutesAfterMidnight;
    return PopScope<Object?>(
      canPop: !_dirty || _allowPop,
      onPopInvokedWithResult: (didPop, _) => _onPop(didPop),
      child: _EditorFrame(
        title: _draft.title,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enabled'),
            subtitle: const Text('Matikan untuk menyembunyikan dari Today.'),
            value: _draft.isEnabled,
            onChanged: (value) =>
                setState(() => _draft = _draft.copyWith(isEnabled: value)),
          ),
          if (_timeEditable)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Preferred time'),
              subtitle: Text(time == null ? '--:--' : _formatMinutes(time)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            )
          else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Schedule'),
              subtitle: Text('Based on prayer time'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder'),
            value: _draft.reminderEnabled,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(reminderEnabled: value),
            ),
          ),
          DaisthButton(
            label: _saving ? 'Saving...' : 'Save Changes',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: DaisthSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _reset,
              child: const Text('Reset to Default'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRoutineEditor extends StatefulWidget {
  const _CustomRoutineEditor({
    required this.repository,
    required this.recordRepository,
    required this.noticeController,
    required this.initial,
    this.initialSteps = const [],
  });
  final RoutineRepository repository;
  final RoutineRecordRepository recordRepository;
  final DaisthNoticeController noticeController;
  final RoutineDefinition initial;
  final List<RoutineStepDefinition> initialSteps;
  @override
  State<_CustomRoutineEditor> createState() => _CustomRoutineEditorState();
}

class _CustomRoutineEditorState extends State<_CustomRoutineEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _description = TextEditingController(
    text: widget.initial.description ?? '',
  );
  late bool _enabled = widget.initial.isEnabled;
  late bool _reminder = widget.initial.reminderEnabled;
  late TimeOfDay _time;
  late final List<_StepDraft> _steps = [
    for (final step in widget.initialSteps)
      _StepDraft(
        id: step.stepId,
        controller: TextEditingController(text: step.title),
        required: step.isRequired,
      ),
  ];
  bool _saving = false;
  String? _formError;
  bool _allowPop = false;

  bool get _dirty {
    if (_title.text != widget.initial.title ||
        _description.text != (widget.initial.description ?? '') ||
        _enabled != widget.initial.isEnabled ||
        _reminder != widget.initial.reminderEnabled ||
        _time.hour * 60 + _time.minute !=
            widget.initial.schedule.minutesAfterMidnight ||
        _steps.length != widget.initialSteps.length) {
      return true;
    }
    for (var index = 0; index < _steps.length; index++) {
      final draft = _steps[index];
      final initial = widget.initialSteps[index];
      if (draft.id != initial.stepId ||
          draft.controller.text != initial.title ||
          draft.required != initial.isRequired ||
          index != initial.sortOrder) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final minutes = widget.initial.schedule.minutesAfterMidnight ?? 8 * 60;
    _time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _addStep() => setState(() => _steps.add(_StepDraft()));

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index).controller.dispose();
    });
  }

  void _showError(String message) => widget.noticeController.show(
    context,
    type: DaisthNoticeType.error,
    title: message,
  );

  Future<void> _save() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty) {
      setState(() => _formError = 'Masukkan nama rutinitas.');
      return;
    }
    if (title.length > 50) {
      setState(() => _formError = 'Nama rutinitas maksimal 50 karakter.');
      return;
    }
    if (description.length > 160) {
      setState(() => _formError = 'Deskripsi maksimal 160 karakter.');
      return;
    }
    if (_steps.any((step) => step.controller.text.trim().isEmpty)) {
      setState(() => _formError = 'Isi atau hapus item checklist yang kosong.');
      return;
    }
    if (_steps.isNotEmpty && !_steps.any((step) => step.required)) {
      setState(() => _formError = 'Pilih setidaknya satu langkah wajib.');
      return;
    }
    final now = DateTime.now().toUtc();
    final definition = widget.initial.copyWith(
      title: title,
      description: description,
      clearDescription: description.isEmpty,
      isEnabled: _enabled,
      schedule: RoutineSchedule.fixed(_time.hour * 60 + _time.minute),
      reminderEnabled: _reminder,
      updatedAt: now,
    );
    final originalById = {
      for (final step in widget.initialSteps) step.stepId: step,
    };
    final stepDefinitions = <RoutineStepDefinition>[];
    for (var i = 0; i < _steps.length; i++) {
      final draft = _steps[i];
      final old = draft.id == null ? null : originalById[draft.id];
      stepDefinitions.add(
        RoutineStepDefinition(
          routineId: definition.id,
          stepId: draft.id ?? createCustomRoutineStepId(now: now),
          title: draft.controller.text.trim(),
          isRequired: draft.required,
          isArchived: false,
          sortOrder: i,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      await SaveCustomRoutineUseCase(
        routines: widget.repository,
        records: widget.recordRepository,
      )(definition: definition, steps: stepDefinitions, now: now);
      if (mounted) {
        _allowPop = true;
        Navigator.pop(context, true);
      }
    } on RoutineDefinitionValidationException catch (error) {
      setState(() => _formError = error.message);
    } catch (_) {
      _showError('Rutinitas belum dapat disimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _ConfirmSheet(
        title: 'Delete this routine?',
        message: 'Past records will be kept.',
        confirmLabel: 'Delete Routine',
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.archiveCustomRoutine(
        widget.initial.id,
        DateTime.now().toUtc(),
      );
      if (mounted) {
        _allowPop = true;
        Navigator.pop(context, true);
      }
    } catch (_) {
      _showError('Rutinitas belum dapat dihapus.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onPop(bool didPop) async {
    if (didPop || !_dirty || _allowPop || _saving) return;
    final discard = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => const _ConfirmSheet(
        title: 'Discard changes?',
        message: 'Your unsaved routine changes will be lost.',
        confirmLabel: 'Discard Changes',
      ),
    );
    if (discard == true && mounted) {
      _allowPop = true;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_dirty || _allowPop,
    onPopInvokedWithResult: (didPop, _) => _onPop(didPop),
    child: _EditorFrame(
      title: widget.initial.title.isEmpty ? 'Add Routine' : 'Edit Routine',
      children: [
        TextFormField(
          controller: _title,
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Routine name *'),
        ),
        TextFormField(
          controller: _description,
          maxLength: 160,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time *'),
          subtitle: Text(_time.format(context)),
          trailing: const Icon(Icons.access_time),
          onTap: _pickTime,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enabled'),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reminder'),
          value: _reminder,
          onChanged: (value) => setState(() => _reminder = value),
        ),
        const SizedBox(height: DaisthSpacing.sm),
        Row(
          children: [
            const Expanded(child: Text('Checklist steps')),
            TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add step'),
            ),
          ],
        ),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DaisthSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _steps[i].controller,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Step ${i + 1}',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _steps[i].required ? 'Required' : 'Optional',
                  onPressed: () =>
                      setState(() => _steps[i].required = !_steps[i].required),
                  icon: Icon(
                    _steps[i].required
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove step',
                  onPressed: () => _removeStep(i),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        if (_steps.isNotEmpty)
          Text(
            'Tap the checkbox to switch a step between required and optional.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (_formError != null) ...[
          const SizedBox(height: DaisthSpacing.xs),
          Text(
            _formError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: DaisthSpacing.md),
        DaisthButton(
          label: _saving ? 'Saving...' : 'Save Routine',
          onPressed: _saving ? null : _save,
        ),
        if (widget.initial.title.isNotEmpty) ...[
          const SizedBox(height: DaisthSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _archive,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete Routine'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _StepDraft {
  _StepDraft({this.id, TextEditingController? controller, this.required = true})
    : controller = controller ?? TextEditingController();
  final String? id;
  final TextEditingController controller;
  bool required;
}

String _formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

class _EditorFrame extends StatelessWidget {
  const _EditorFrame({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: DaisthSpacing.screenHorizontal,
      right: DaisthSpacing.screenHorizontal,
      top: DaisthSpacing.lg,
      bottom: MediaQuery.viewInsetsOf(context).bottom + DaisthSpacing.lg,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DaisthSpacing.md),
          ...children,
        ],
      ),
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });
  final String title;
  final String message;
  final String confirmLabel;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DaisthSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DaisthSpacing.sm),
        Text(message),
        const SizedBox(height: DaisthSpacing.lg),
        DaisthButton(
          label: confirmLabel,
          onPressed: () => Navigator.pop(context, true),
        ),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ),
      ],
    ),
  );
}
