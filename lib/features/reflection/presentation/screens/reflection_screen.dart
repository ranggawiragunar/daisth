import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../app/dependencies/app_dependencies.dart';
import '../../../../core/design_system/components/daisth_notice.dart';
import '../../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../../core/design_system/components/daisth_surface.dart';
import '../../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/reflection_rhythm.dart';
import '../../domain/use_cases/clear_daily_reflection_use_case.dart';
import '../../domain/use_cases/get_daily_reflection_use_case.dart';
import '../../domain/use_cases/save_daily_reflection_use_case.dart';
import '../view_models/reflection_view_model.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({
    required this.day,
    required this.historical,
    required this.dependencies,
    required this.noticeController,
    super.key,
  });

  final CalendarDay day;
  final bool historical;
  final AppDependencies dependencies;
  final DaisthNoticeController noticeController;

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  late final ReflectionViewModel _model;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repository = widget.dependencies.reflectionRepository;
    _model = ReflectionViewModel(
      day: widget.day,
      getReflection: GetDailyReflectionUseCase(repository),
      saveReflection: SaveDailyReflectionUseCase(repository),
      clearReflection: ClearDailyReflectionUseCase(repository),
    )..addListener(_onChanged);
    unawaited(
      _model.initialize().then((_) {
        if (mounted) _syncNoteController();
      }),
    );
  }

  @override
  void dispose() {
    _model
      ..removeListener(_onChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncNoteController() {
    _noteController.value = TextEditingValue(
      text: _model.note,
      selection: TextSelection.collapsed(offset: _model.note.length),
    );
  }

  Future<void> _save() async {
    final saved = await _model.save();
    if (!mounted) return;
    if (saved) {
      _syncNoteController();
      widget.noticeController.show(
        context,
        type: DaisthNoticeType.success,
        title: 'Refleksi tersimpan.',
      );
    } else if (_model.errorMessage != null) {
      _showError(_model.errorMessage!);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus refleksi ini?'),
        content: Text(
          widget.historical
              ? 'Catatan refleksi untuk ${_formattedDay(context)} akan dihapus. Catatan rutinitas tetap tersimpan.'
              : 'Catatan refleksi untuk hari ini akan dihapus. Catatan rutinitas tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus refleksi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await _model.clear();
    if (!mounted) return;
    if (deleted) {
      _noteController.clear();
      widget.noticeController.show(
        context,
        type: DaisthNoticeType.success,
        title: 'Refleksi dihapus.',
      );
    } else if (_model.errorMessage != null) {
      _showError(_model.errorMessage!);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perubahan belum disimpan'),
        content: const Text('Keluar tanpa menyimpan refleksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap di sini'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _showError(String message) => widget.noticeController.show(
    context,
    type: DaisthNoticeType.error,
    title: message,
  );

  String _formattedDay(BuildContext context) => MaterialLocalizations.of(
    context,
  ).formatMediumDate(widget.day.toDateTime());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_model.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _model.isDirty) unawaited(_confirmDiscard());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Daily Reflection')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _model.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DaisthSpacing.xl,
                      DaisthSpacing.md,
                      DaisthSpacing.xl,
                      DaisthSpacing.xxl,
                    ),
                    children: [
                      if (widget.historical) ...[
                        Text(
                          'Editing ${_formattedDay(context)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                      ],
                      Text(
                        'Bagaimana ritmemu hari ini?',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: DaisthSpacing.lg),
                      for (final rhythm in ReflectionRhythm.values)
                        _RhythmChoice(
                          rhythm: rhythm,
                          selected: _model.selectedRhythm == rhythm,
                          onSelected: () => _model.selectRhythm(rhythm),
                        ),
                      if (_model.rhythmError) ...[
                        const SizedBox(height: DaisthSpacing.xs),
                        Text(
                          'Pilih satu gambaran ritmemu untuk menyimpan refleksi.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: DaisthSpacing.xl),
                      Text(
                        'Apa yang ingin kamu ingat dari hari ini?',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: DaisthSpacing.sm),
                      TextField(
                        controller: _noteController,
                        onChanged: _model.updateNote,
                        maxLength: SaveDailyReflectionUseCase.maxNoteLength,
                        maxLines: 4,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Catatan singkat (opsional)',
                          alignLabelWithHint: true,
                          errorText: _model.noteError
                              ? 'Catatan maksimal 500 karakter.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: DaisthSpacing.md),
                      FilledButton.icon(
                        onPressed: _model.isSaving ? null : _save,
                        icon: _model.isSaving
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(PhosphorIconsRegular.floppyDisk),
                        label: const Text('Simpan refleksi'),
                      ),
                      if (_model.savedReflection != null) ...[
                        const SizedBox(height: DaisthSpacing.sm),
                        TextButton.icon(
                          onPressed: _model.isSaving ? null : _delete,
                          icon: const Icon(PhosphorIconsRegular.trash),
                          label: const Text('Hapus refleksi'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _RhythmChoice extends StatelessWidget {
  const _RhythmChoice({
    required this.rhythm,
    required this.selected,
    required this.onSelected,
  });

  final ReflectionRhythm rhythm;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (rhythm) {
      ReflectionRhythm.steady => 'Terasa mengalir',
      ReflectionRhythm.mixed => 'Naik turun',
      ReflectionRhythm.heavy => 'Terasa berat',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: DaisthSpacing.sm),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(18),
          child: DaisthSurface(
            style: selected
                ? DaisthSurfaceStyle.softPrimary
                : DaisthSurfaceStyle.standard,
            child: Row(
              children: [
                Icon(
                  selected
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circle,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: DaisthSpacing.md),
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
