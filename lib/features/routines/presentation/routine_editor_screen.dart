import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../app/dependencies/app_dependencies.dart';
import '../../../core/design_system/assets/daisth_assets.dart';
import '../../../core/design_system/components/daisth_button.dart';
import '../../../core/design_system/components/daisth_feature_visual.dart';
import '../../../core/design_system/components/daisth_notice.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/design_system/components/daisth_surface.dart';
import '../../../core/design_system/tokens/daisth_spacing.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../data/services/routine_attachment_file_service.dart';
import '../domain/models/routine_attachment.dart';
import '../domain/models/routine_content.dart';
import '../domain/models/routine_definition.dart';
import '../domain/models/routine_origin.dart';
import '../domain/models/routine_priority.dart';
import '../domain/models/routine_schedule.dart';
import '../domain/models/routine_step_definition.dart';
import '../domain/use_cases/save_routine_editor_use_case.dart';
import '../domain/use_cases/save_custom_routine_use_case.dart';
import '../domain/use_cases/reset_default_routine_use_case.dart';
import '../data/catalog/default_routine_template_catalog.dart';

class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({required this.dependencies, required this.noticeController, this.routineId, super.key});

  final AppDependencies dependencies;
  final DaisthNoticeController noticeController;
  final String? routineId;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late final String _routineId = widget.routineId ?? createCustomRoutineId();
  late final Future<_EditorInitial> _initial = _load();

  Future<_EditorInitial> _load() async {
    if (widget.routineId == null) {
      final now = DateTime.now().toUtc();
      final definition = RoutineDefinition(id: _routineId, origin: RoutineOrigin.custom, title: '', description: null, isEnabled: true, isArchived: false, schedule: RoutineSchedule.fixed(8 * 60), reminderEnabled: true, priority: RoutinePriority.medium, sortOrder: 100, createdAt: now, updatedAt: now);
      return _EditorInitial(definition, const [], null, const []);
    }
    await widget.dependencies.ensureRoutineDefinitionsReady();
    final existing = await widget.dependencies.routineRepository.getRoutine(_routineId);
    if (existing == null) {
      throw StateError('Routine not found');
    }
    final definition = existing;
    final steps = definition.origin == RoutineOrigin.custom ? await widget.dependencies.routineRepository.getSteps(_routineId) : const <RoutineStepDefinition>[];
    final content = await widget.dependencies.routineContentRepository.getForRoutine(_routineId);
    final attachments = await widget.dependencies.routineAttachmentRepository.listForRoutine(_routineId);
    return _EditorInitial(definition, steps, content, attachments);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_EditorInitial>(
    future: _initial,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(DaisthLocalizations.text(context, id: 'Rutinitas tidak ditemukan.', en: 'Routine not found.')),
          ),
        );
      }
      return _RoutineEditorForm(key: ValueKey('routine-editor-$_routineId'), initial: snapshot.data!, dependencies: widget.dependencies, noticeController: widget.noticeController, fileService: widget.dependencies.routineAttachmentFileService);
    },
  );
}

class _EditorInitial {
  const _EditorInitial(this.definition, this.steps, this.content, this.images);
  final RoutineDefinition definition;
  final List<RoutineStepDefinition> steps;
  final RoutineContent? content;
  final List<RoutineAttachment> images;
}

class _RoutineEditorForm extends StatefulWidget {
  const _RoutineEditorForm({required this.initial, required this.dependencies, required this.noticeController, required this.fileService, super.key});

  final _EditorInitial initial;
  final AppDependencies dependencies;
  final DaisthNoticeController noticeController;
  final RoutineAttachmentFileService fileService;

  @override
  State<_RoutineEditorForm> createState() => _RoutineEditorFormState();
}

class _RoutineEditorFormState extends State<_RoutineEditorForm> {
  late final RoutineDefinition _initial = widget.initial.definition;
  late final TextEditingController _title = TextEditingController(text: _initial.title);
  late final TextEditingController _description = TextEditingController(text: _initial.description ?? '');
  late final QuillController _quill = _makeQuillController();
  late bool _enabled = _initial.isEnabled;
  late bool _reminder = _initial.reminderEnabled;
  late TimeOfDay _time = _initial.schedule.minutesAfterMidnight == null ? const TimeOfDay(hour: 8, minute: 0) : TimeOfDay(hour: _initial.schedule.minutesAfterMidnight! ~/ 60, minute: _initial.schedule.minutesAfterMidnight! % 60);
  late final List<_StepDraft> _steps = [for (final step in widget.initial.steps) _StepDraft.fromDefinition(step)];
  late final List<RoutineAttachment> _images = [...widget.initial.images];
  final List<_StagedDraft> _staged = [];
  final Set<String> _removedIds = {};
  bool _dirty = false;
  bool _saving = false;
  bool _allowPop = false;
  String? _formError;

  bool get _isCustom => _initial.origin == RoutineOrigin.custom;
  bool get _isNew => _initial.title.isEmpty && _isCustom;
  bool get _timeEditable => _isCustom || const {'sholat-malam', 'dhuha', 'penutup-hari'}.contains(_initial.id);

  QuillController _makeQuillController() {
    final initial = widget.initial.content;
    if (initial == null || initial.serializedDelta.isEmpty) {
      return QuillController.basic();
    }
    try {
      return QuillController(document: Document.fromJson(jsonDecode(initial.serializedDelta) as List), selection: const TextSelection.collapsed(offset: 0));
    } catch (_) {
      return QuillController.basic();
    }
  }

  @override
  void initState() {
    super.initState();
    _quill.addListener(_markDirty);
    _title.addListener(_markDirty);
    _description.addListener(_markDirty);
    if (Platform.isAndroid) _recoverPickerData();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _quill.dispose();
    for (final step in _steps) {
      step.controller.dispose();
    }
    for (final staged in _staged) {
      widget.fileService.deleteStaged(staged.image.path);
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _showNotice(String message) => widget.noticeController.show(context, type: DaisthNoticeType.error, title: message);

  Future<void> _recoverPickerData() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty || response.files == null) return;
      await _stageFiles(response.files!);
    } catch (_) {
      // Lost-data recovery is best-effort on platforms that do not expose it.
    }
  }

  Future<void> _pickImages() async {
    final remaining = RoutineAttachment.maxAttachmentsPerRoutine - _images.length - _staged.length;
    if (remaining <= 0) {
      _showNotice(DaisthLocalizations.text(context, id: 'Maksimal 8 gambar untuk satu rutinitas.', en: 'A routine can have up to 8 images.'));
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(limit: remaining);
      await _stageFiles(files);
    } catch (_) {
      if (mounted) {
        _showNotice(DaisthLocalizations.text(context, id: 'Gambar belum dapat dibuka.', en: 'Images could not be opened.'));
      }
    }
  }

  Future<void> _stageFiles(List<XFile> files) async {
    if (files.isEmpty || !mounted) return;
    final remaining = RoutineAttachment.maxAttachmentsPerRoutine - _images.length - _staged.length;
    if (files.length > remaining) {
      _showNotice(DaisthLocalizations.text(context, id: 'Pilih maksimal $remaining gambar lagi.', en: 'Select up to $remaining more images.'));
    }
    for (final file in files.take(remaining)) {
      try {
        final image = await widget.fileService.stageImage(file: file, routineId: _initial.id);
        if (mounted) setState(() => _staged.add(_StagedDraft(image)));
        _markDirty();
      } on RoutineAttachmentTooLargeException {
        if (mounted) {
          _showNotice(DaisthLocalizations.text(context, id: 'Gambar terlalu besar. Coba pilih gambar lain.', en: 'This image is too large. Please choose another image.'));
        }
      } catch (_) {
        if (mounted) {
          _showNotice(DaisthLocalizations.text(context, id: 'Gambar belum dapat diproses.', en: 'This image could not be processed.'));
        }
      }
    }
  }

  void _removeExisting(RoutineAttachment attachment) {
    setState(() {
      _images.removeWhere((item) => item.id == attachment.id);
      _removedIds.add(attachment.id);
    });
    _markDirty();
  }

  Future<void> _removeStaged(_StagedDraft image) async {
    await widget.fileService.deleteStaged(image.image.path);
    if (!mounted) return;
    setState(() => _staged.remove(image));
    _markDirty();
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null && mounted) {
      setState(() {
        _time = value;
        _markDirty();
      });
    }
  }

  void _addStep() {
    setState(() => _steps.add(_StepDraft.create()));
    _markDirty();
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index).controller.dispose());
    _markDirty();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _allowPop) return true;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DaisthLocalizations.text(context, id: 'Buang perubahan?', en: 'Discard changes?')),
        content: Text(DaisthLocalizations.text(context, id: 'Perubahan yang belum disimpan akan hilang.', en: 'Your unsaved changes will be lost.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(DaisthLocalizations.text(context, id: 'Lanjut mengedit', en: 'Keep Editing')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(DaisthLocalizations.text(context, id: 'Buang', en: 'Discard')),
          ),
        ],
      ),
    );
    if (answer == true) {
      await widget.fileService.cleanStaging(routineId: _initial.id);
      _allowPop = true;
    }
    return answer == true;
  }

  Future<void> _save() async {
    final now = DateTime.now().toUtc();
    final title = _title.text.trim();
    if (_isCustom && title.isEmpty) {
      setState(() => _formError = DaisthLocalizations.text(context, id: 'Masukkan nama rutinitas.', en: 'Enter a routine name.'));
      return;
    }
    if (_isCustom && title.length > 50) {
      setState(() => _formError = DaisthLocalizations.text(context, id: 'Nama rutinitas maksimal 50 karakter.', en: 'Routine names can be up to 50 characters.'));
      return;
    }
    if (_steps.any((step) => step.controller.text.trim().isEmpty) || (_steps.isNotEmpty && !_steps.any((step) => step.required))) {
      setState(() => _formError = DaisthLocalizations.text(context, id: 'Periksa kembali langkah checklist.', en: 'Please check the checklist steps.'));
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final permanentPaths = <String>[];
    var databaseCommitted = false;
    try {
      final newAttachments = <RoutineAttachment>[];
      for (var i = 0; i < _staged.length; i++) {
        final draft = _staged[i];
        final id = '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32).toRadixString(16)}';
        final relative = await widget.fileService.moveToPermanent(image: draft.image, routineId: _initial.id, attachmentId: id);
        permanentPaths.add(relative);
        newAttachments.add(RoutineAttachment(id: id, routineId: _initial.id, type: 'image', localRelativePath: relative, originalFileName: draft.image.originalFileName, mimeType: draft.image.mimeType, byteSize: draft.image.byteSize, width: draft.image.width, height: draft.image.height, sortOrder: _images.length + i, contentSha256: draft.image.sha256, createdAt: now, updatedAt: now));
      }
      final plainText = _quill.document.toPlainText().trim();
      final delta = jsonEncode(_quill.document.toDelta().toJson());
      final content = plainText.isEmpty ? null : RoutineContent(routineId: _initial.id, serializedDelta: delta, plainText: plainText, formatVersion: 1, createdAt: widget.initial.content?.createdAt ?? now, updatedAt: now);
      final definition = _initial.copyWith(title: _isCustom ? title : null, description: _isCustom ? _description.text.trim() : null, clearDescription: _isCustom && _description.text.trim().isEmpty, isEnabled: _enabled, reminderEnabled: _reminder, schedule: _timeEditable ? RoutineSchedule.fixed(_time.hour * 60 + _time.minute) : null, updatedAt: now);
      final stepDefinitions = _isCustom ? [for (var i = 0; i < _steps.length; i++) _steps[i].toDefinition(_initial.id, i, now)] : null;
      await SaveRoutineEditorUseCase(editorRepository: widget.dependencies.routineEditorRepository, routines: widget.dependencies.routineRepository, records: widget.dependencies.routineRecordRepository)(definition: definition, steps: stepDefinitions, content: content, attachments: [..._images, ...newAttachments], removedAttachmentIds: _removedIds, now: now);
      databaseCommitted = true;
      for (final id in _removedIds) {
        final old = widget.initial.images.where((item) => item.id == id);
        if (old.isNotEmpty) {
          try {
            await widget.fileService.deleteRelative(old.first.localRelativePath);
          } catch (_) {
            // Stale unreferenced files are removed by startup orphan cleanup.
          }
        }
      }
      await widget.fileService.cleanStaging(routineId: _initial.id);
      _allowPop = true;
      if (mounted) Navigator.pop(context, true);
    } on RoutineDefinitionValidationException catch (error) {
      setState(() => _formError = error.message);
      if (!databaseCommitted) {
        for (final path in permanentPaths) {
          await widget.fileService.deleteRelative(path);
        }
      }
    } catch (_) {
      if (!databaseCommitted) {
        for (final path in permanentPaths) {
          await widget.fileService.deleteRelative(path);
        }
      }
      if (mounted) {
        _showNotice(DaisthLocalizations.text(context, id: 'Rutinitas belum dapat disimpan. Coba lagi.', en: 'Routine could not be saved. Please try again.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DaisthLocalizations.text(context, id: 'Arsipkan rutinitas?', en: 'Archive this routine?')),
        content: Text(DaisthLocalizations.text(context, id: 'Riwayat dan gambar tetap tersimpan.', en: 'Its history and images will be kept.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(DaisthLocalizations.text(context, id: 'Arsipkan', en: 'Archive')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.dependencies.routineRepository.archiveCustomRoutine(_initial.id, DateTime.now().toUtc());
      _allowPop = true;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _showNotice(DaisthLocalizations.text(context, id: 'Rutinitas belum dapat diarsipkan.', en: 'Routine could not be archived.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DaisthLocalizations.text(context, id: 'Reset rutinitas ini?', en: 'Reset this routine?')),
        content: Text(DaisthLocalizations.text(context, id: 'Jadwal dan pengingat kembali ke pengaturan bawaan. Catatan dan riwayat tetap tersimpan.', en: 'Schedule and reminder settings return to Daisth defaults. Notes and history stay saved.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(DaisthLocalizations.text(context, id: 'Batal', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(DaisthLocalizations.text(context, id: 'Reset', en: 'Reset')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ResetDefaultRoutineUseCase(repository: widget.dependencies.routineRepository, templates: DefaultRoutineTemplateCatalog.definitions)(_initial.id);
      _allowPop = true;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _showNotice(DaisthLocalizations.text(context, id: 'Rutinitas belum dapat direset.', en: 'Routine could not be reset.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<Object?>(
      canPop: !_dirty || _allowPop || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        final discard = await _confirmDiscard();
        if (!context.mounted || !discard) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            DaisthLocalizations.text(context, id: _isNew ? 'Buat Rutinitas' : 'Edit Rutinitas', en: _isNew ? 'Create Routine' : 'Edit Routine'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () async {
              if (await _confirmDiscard() && context.mounted) {
                Navigator.maybePop(context);
              }
            },
          ),
        ),
        body: ListView(
          key: const ValueKey('routine-editor-scroll-view'),
          padding: const EdgeInsets.fromLTRB(DaisthSpacing.screenHorizontal, DaisthSpacing.md, DaisthSpacing.screenHorizontal, DaisthSpacing.xl),
          children: [
            if (_isCustom) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DaisthLocalizations.text(context, id: 'Dasar', en: 'Basics'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 42,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DaisthFeatureVisual(asset: DaisthAssets.routineEditorHeader, height: 42, width: 60),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _title,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: DaisthLocalizations.text(context, id: 'Nama rutinitas *', en: 'Routine name *'),
                ),
              ),
              TextField(
                controller: _description,
                maxLength: 160,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: DaisthLocalizations.text(context, id: 'Deskripsi', en: 'Description'),
                ),
              ),
              const SizedBox(height: DaisthSpacing.md),
              _section(context, DaisthLocalizations.text(context, id: 'Jadwal & pengingat', en: 'Schedule & reminder')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DaisthLocalizations.text(context, id: 'Waktu', en: 'Time')),
                subtitle: Text(_time.format(context)),
                trailing: const Icon(PhosphorIconsRegular.clock),
                onTap: _pickTime,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DaisthLocalizations.text(context, id: 'Aktif', en: 'Enabled')),
                value: _enabled,
                onChanged: (value) => setState(() {
                  _enabled = value;
                  _markDirty();
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DaisthLocalizations.text(context, id: 'Pengingat', en: 'Reminder')),
                value: _reminder,
                onChanged: (value) => setState(() {
                  _reminder = value;
                  _markDirty();
                }),
              ),
              const SizedBox(height: DaisthSpacing.md),
              _section(context, DaisthLocalizations.text(context, id: 'Checklist', en: 'Checklist')),
              for (var i = 0; i < _steps.length; i++) _stepRow(context, i),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: Text(DaisthLocalizations.text(context, id: 'Tambah langkah', en: 'Add step')),
                ),
              ),
            ] else ...[
              _section(context, DaisthLocalizations.text(context, id: 'Rutinitas bawaan', en: 'Default routine')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DaisthLocalizations.text(context, id: 'Aktif', en: 'Enabled')),
                subtitle: Text(DaisthLocalizations.text(context, id: 'Matikan untuk menyembunyikan dari Hari Ini.', en: 'Turn off to hide from Today.')),
                value: _enabled,
                onChanged: (value) => setState(() {
                  _enabled = value;
                  _markDirty();
                }),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_timeEditable ? DaisthLocalizations.text(context, id: 'Waktu pilihan', en: 'Preferred time') : DaisthLocalizations.text(context, id: 'Jadwal', en: 'Schedule')),
                subtitle: Text(_timeEditable ? _time.format(context) : DaisthLocalizations.text(context, id: 'Mengikuti waktu salat', en: 'Based on prayer time')),
                trailing: _timeEditable ? const Icon(PhosphorIconsRegular.clock) : null,
                onTap: _timeEditable ? _pickTime : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DaisthLocalizations.text(context, id: 'Pengingat', en: 'Reminder')),
                value: _reminder,
                onChanged: (value) => setState(() {
                  _reminder = value;
                  _markDirty();
                }),
              ),
            ],
            const SizedBox(height: DaisthSpacing.md),
            _section(context, DaisthLocalizations.text(context, id: 'Catatan', en: 'Notes')),
            DaisthSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  QuillSimpleToolbar(controller: _quill, config: const QuillSimpleToolbarConfig(showFontFamily: false, showFontSize: false, showInlineCode: false, showColorButton: false, showBackgroundColorButton: false, showListCheck: false, showCodeBlock: false, showAlignmentButtons: false, showIndent: false, showSearchButton: false, showSubscript: false, showSuperscript: false, multiRowsDisplay: true)),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 160),
                    child: Padding(
                      padding: const EdgeInsets.all(DaisthSpacing.md),
                      child: QuillEditor.basic(
                        controller: _quill,
                        config: QuillEditorConfig(
                          placeholder: DaisthLocalizations.text(context, id: 'Tambahkan catatan atau hal yang ingin diingat...', en: 'Add notes or anything you want to remember...'),
                          padding: EdgeInsets.zero,
                          customStyles: DefaultStyles(placeHolder: DefaultTextBlockStyle(Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black45), HorizontalSpacing(1, 1), VerticalSpacing(1, 1), VerticalSpacing(1, 1), BoxDecoration())),
                          minHeight: 160,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DaisthSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _section(context, DaisthLocalizations.text(context, id: 'Gambar', en: 'Images')),
                ),
                Text('${_images.length + _staged.length}/${RoutineAttachment.maxAttachmentsPerRoutine}', style: theme.textTheme.labelMedium),
              ],
            ),
            if (_images.isEmpty && _staged.isEmpty)
              DaisthSurface(
                child: Row(
                  children: [
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [DaisthFeatureVisual(asset: DaisthAssets.routineAttachmentEmpty, height: 58, width: 72)],
                    ),
                    const SizedBox(width: DaisthSpacing.md),
                    Expanded(
                      child: Text(DaisthLocalizations.text(context, id: 'Tambahkan gambar dari galeri jika diperlukan.', en: 'Add images from your gallery if you like.')),
                    ),
                  ],
                ),
              )
            else
              _imageGrid(context),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickImages,
                icon: Icon(PhosphorIconsRegular.image),
                label: Text(DaisthLocalizations.text(context, id: 'Pilih dari galeri', en: 'Choose from gallery')),
              ),
            ),
            if (_isCustom && !_isNew)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _archive,
                  icon: const Icon(PhosphorIconsRegular.archive),
                  label: Text(DaisthLocalizations.text(context, id: 'Arsipkan rutinitas', en: 'Archive routine')),
                ),
              ),
            if (!_isCustom)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _resetDefault,
                  icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise),
                  label: Text(DaisthLocalizations.text(context, id: 'Kembalikan ke Bawaan', en: 'Reset to Default')),
                ),
              ),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(top: DaisthSpacing.sm),
                child: Text(_formError!, style: TextStyle(color: theme.colorScheme.error)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DaisthSpacing.screenHorizontal, DaisthSpacing.sm, DaisthSpacing.screenHorizontal, DaisthSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: DaisthButton(
                label: _saving ? DaisthLocalizations.text(context, id: 'Menyimpan...', en: 'Saving...') : DaisthLocalizations.text(context, id: 'Simpan Rutinitas', en: 'Save Routine'),
                compact: true,
                onPressed: _saving ? null : _save,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: DaisthSpacing.sm),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _stepRow(BuildContext context, int index) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: _steps[index].controller,
          maxLength: 80,
          onChanged: (_) => _markDirty(),
          decoration: InputDecoration(
            labelText: DaisthLocalizations.text(context, id: 'Langkah ${index + 1}', en: 'Step ${index + 1}'),
          ),
        ),
      ),
      Checkbox(
        value: _steps[index].required,
        onChanged: (value) => setState(() {
          _steps[index].required = value ?? true;
          _markDirty();
        }),
      ),
      IconButton(onPressed: () => _removeStep(index), icon: const Icon(PhosphorIconsRegular.x)),
    ],
  );

  Widget _imageGrid(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: DaisthSpacing.sm,
    crossAxisSpacing: DaisthSpacing.sm,
    children: [
      for (final attachment in _images) _imageTile(attachment: attachment),
      for (final staged in _staged) _imageTile(staged: staged),
    ],
  );

  Widget _imageTile({RoutineAttachment? attachment, _StagedDraft? staged}) {
    final Future<File?> file = staged != null ? Future.value(File(staged.image.path)) : widget.fileService.resolve(attachment?.localRelativePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<File?>(
            future: file,
            builder: (context, snapshot) => snapshot.data == null ? const ColoredBox(color: Color(0x12000000), child: Icon(PhosphorIconsRegular.image)) : Image.file(snapshot.data!, fit: BoxFit.cover, cacheWidth: 360),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(onPressed: () => staged == null ? _removeExisting(attachment!) : _removeStaged(staged), icon: const Icon(PhosphorIconsRegular.x, size: 18)),
          ),
        ],
      ),
    );
  }
}

class _StagedDraft {
  const _StagedDraft(this.image);
  final StagedRoutineImage image;
}

class _StepDraft {
  _StepDraft({required this.id, required this.controller, required this.required, this.createdAt});
  factory _StepDraft.fromDefinition(RoutineStepDefinition value) => _StepDraft(
    id: value.stepId,
    controller: TextEditingController(text: value.title),
    required: value.isRequired,
    createdAt: value.createdAt,
  );
  factory _StepDraft.create() => _StepDraft(id: null, controller: TextEditingController(), required: true);
  final String? id;
  final TextEditingController controller;
  bool required;
  final DateTime? createdAt;
  RoutineStepDefinition toDefinition(String routineId, int order, DateTime now) => RoutineStepDefinition(
    routineId: routineId,
    stepId: id ?? createCustomRoutineStepId(now: now),
    title: controller.text.trim(),
    isRequired: required,
    isArchived: false,
    sortOrder: order,
    createdAt: createdAt ?? now,
    updatedAt: now,
  );
}
