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
import '../../../../core/localization/daisth_localizations.dart';
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
        title: DaisthLocalizations.text(
          context,
          id: 'Refleksi tersimpan.',
          en: 'Reflection saved.',
        ),
      );
    } else if (_model.errorMessage != null) {
      _showError(_model.errorMessage!);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Hapus refleksi ini?',
            en: 'Delete this reflection?',
          ),
        ),
        content: Text(
          widget.historical
              ? DaisthLocalizations.text(
                  context,
                  id: 'Catatan refleksi untuk ${_formattedDay(context)} akan dihapus. Catatan rutinitas tetap tersimpan.',
                  en: 'The reflection for ${_formattedDay(context)} will be deleted. Routine records will remain.',
                )
              : DaisthLocalizations.text(
                  context,
                  id: 'Catatan refleksi untuk hari ini akan dihapus. Catatan rutinitas tetap tersimpan.',
                  en: "Today's reflection will be deleted. Routine records will remain.",
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Hapus refleksi',
                en: 'Delete reflection',
              ),
            ),
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
        title: DaisthLocalizations.text(
          context,
          id: 'Refleksi dihapus.',
          en: 'Reflection deleted.',
        ),
      );
    } else if (_model.errorMessage != null) {
      _showError(_model.errorMessage!);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DaisthLocalizations.text(
            context,
            id: 'Perubahan belum disimpan',
            en: 'Unsaved changes',
          ),
        ),
        content: Text(
          DaisthLocalizations.text(
            context,
            id: 'Keluar tanpa menyimpan refleksi ini?',
            en: 'Leave without saving this reflection?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Tetap di sini',
                en: 'Stay here',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              DaisthLocalizations.text(context, id: 'Keluar', en: 'Leave'),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _showError(String message) => widget.noticeController.show(
    context,
    type: DaisthNoticeType.error,
    title: switch (message) {
      'Refleksi belum dapat dimuat. Coba lagi.' => DaisthLocalizations.text(
        context,
        id: message,
        en: 'Reflection could not be loaded. Try again.',
      ),
      'Refleksi belum dapat disimpan. Coba lagi.' => DaisthLocalizations.text(
        context,
        id: message,
        en: 'Reflection could not be saved. Try again.',
      ),
      'Refleksi belum dapat dihapus. Coba lagi.' => DaisthLocalizations.text(
        context,
        id: message,
        en: 'Reflection could not be deleted. Try again.',
      ),
      _ => message,
    },
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
        appBar: AppBar(
          title: Text(
            DaisthLocalizations.text(
              context,
              id: 'Refleksi Harian',
              en: 'Daily Reflection',
            ),
          ),
        ),
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
                          DaisthLocalizations.text(
                            context,
                            id: 'Mengedit ${_formattedDay(context)}',
                            en: 'Editing ${_formattedDay(context)}',
                          ),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: DaisthSpacing.md),
                      ],
                      Text(
                        DaisthLocalizations.text(
                          context,
                          id: 'Bagaimana ritmemu hari ini?',
                          en: 'How did your day feel?',
                        ),
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
                          DaisthLocalizations.text(
                            context,
                            id: 'Pilih satu gambaran ritmemu untuk menyimpan refleksi.',
                            en: 'Choose a rhythm to save your reflection.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: DaisthSpacing.xl),
                      Text(
                        DaisthLocalizations.text(
                          context,
                          id: 'Apa yang ingin kamu ingat dari hari ini?',
                          en: 'What would you like to remember from today?',
                        ),
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
                          hintText: DaisthLocalizations.text(
                            context,
                            id: 'Catatan singkat (opsional)',
                            en: 'A short note (optional)',
                          ),
                          alignLabelWithHint: true,
                          errorText: _model.noteError
                              ? DaisthLocalizations.text(
                                  context,
                                  id: 'Catatan maksimal 500 karakter.',
                                  en: 'Notes can be up to 500 characters.',
                                )
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
                        label: Text(
                          DaisthLocalizations.text(
                            context,
                            id: 'Simpan refleksi',
                            en: 'Save reflection',
                          ),
                        ),
                      ),
                      if (_model.savedReflection != null) ...[
                        const SizedBox(height: DaisthSpacing.sm),
                        TextButton.icon(
                          onPressed: _model.isSaving ? null : _delete,
                          icon: const Icon(PhosphorIconsRegular.trash),
                          label: Text(
                            DaisthLocalizations.text(
                              context,
                              id: 'Hapus refleksi',
                              en: 'Delete reflection',
                            ),
                          ),
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
      ReflectionRhythm.steady => DaisthLocalizations.text(
        context,
        id: 'Terasa mengalir',
        en: 'Felt steady',
      ),
      ReflectionRhythm.mixed => DaisthLocalizations.text(
        context,
        id: 'Naik turun',
        en: 'Up and down',
      ),
      ReflectionRhythm.heavy => DaisthLocalizations.text(
        context,
        id: 'Terasa berat',
        en: 'Felt heavy',
      ),
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
