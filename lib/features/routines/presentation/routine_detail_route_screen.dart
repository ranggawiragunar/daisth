import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

import '../../../app/dependencies/app_dependencies.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/time/domain/models/calendar_day.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../data/resolvers/routine_resolver.dart';
import '../domain/models/routine_attachment.dart';
import '../domain/models/routine_content.dart';
import '../../auth/domain/models/auth_session.dart';
import 'routine_detail_screen.dart';

class RoutineDetailRouteScreen extends StatefulWidget {
  const RoutineDetailRouteScreen({
    required this.routineId,
    required this.dependencies,
    required this.noticeController,
    this.calendarDay,
    this.historical = false,
    super.key,
  });

  final String routineId;
  final AppDependencies dependencies;
  final DaisthNoticeController noticeController;
  final CalendarDay? calendarDay;
  final bool historical;

  @override
  State<RoutineDetailRouteScreen> createState() =>
      _RoutineDetailRouteScreenState();
}

class _RoutineDetailRouteScreenState extends State<RoutineDetailRouteScreen> {
  late final Future<ResolvedRoutine?> _routine = _load();
  late final Future<_RoutineOptionalData> _optionalData = _loadOptionalData();

  @override
  Widget build(BuildContext context) => FutureBuilder<ResolvedRoutine?>(
    future: _routine,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          body: Center(
            child: Text(
              DaisthLocalizations.text(
                context,
                id: 'Memuat rutinitas…',
                en: 'Loading routine…',
              ),
            ),
          ),
        );
      }
      final resolved = snapshot.data;
      if (snapshot.hasError || resolved == null) {
        return RoutineUnavailableScreen(routineId: widget.routineId);
      }
      return FutureBuilder<_RoutineOptionalData>(
        future: _optionalData,
        builder: (context, optionalSnapshot) {
          final optional = optionalSnapshot.data;
          return RoutineDetailScreen(
            key: ValueKey('routine-detail-${widget.routineId}'),
            routine: resolved.routine,
            noticeController: widget.noticeController,
            routineRecordRepository:
                widget.dependencies.routineRecordRepository,
            setRoutineStepCompletion:
                widget.dependencies.setRoutineStepCompletion,
            markRoutineComplete: widget.dependencies.markRoutineComplete,
            markRoutineNotToday: widget.dependencies.markRoutineNotToday,
            prayerScheduleSession: widget.historical
                ? null
                : widget.dependencies.prayerScheduleSession,
            calendarDay: widget.calendarDay,
            historical: widget.historical,
            userContent: optional?.content,
            attachments: optional?.attachments ?? const [],
            attachmentFileService:
                widget.dependencies.routineAttachmentFileService,
            resolveRemoteAttachment: _resolveRemoteAttachment,
          );
        },
      );
    },
  );

  String get routineId => widget.routineId;
  AppDependencies get dependencies => widget.dependencies;

  Future<ResolvedRoutine?> _load() async {
    await dependencies.ensureRoutineDefinitionsReady();
    if (widget.historical) {
      final day = widget.calendarDay;
      if (day == null ||
          day.compareTo(CalendarDay.fromDateTime(DateTime.now())) >= 0) {
        return null;
      }
      final recordDay = await dependencies.routineRecordRepository
          .getEarliestRecordDay();
      final definitionDay = await dependencies.routineRepository
          .getEarliestRoutineCreationDay();
      final boundary = recordDay == null
          ? definitionDay
          : definitionDay == null || recordDay.compareTo(definitionDay) <= 0
          ? recordDay
          : definitionDay;
      if (boundary == null || day.compareTo(boundary) < 0) return null;
    }
    return dependencies.routineResolver.resolve(
      routineId,
      includeArchived: widget.historical,
    );
  }

  Future<_RoutineOptionalData> _loadOptionalData() async {
    RoutineContent? content;
    List<RoutineAttachment> attachments = const [];
    try {
      content = await dependencies.routineContentRepository.getForRoutine(
        routineId,
      );
      attachments = await dependencies.routineAttachmentRepository
          .listForRoutine(routineId);
    } catch (_) {
      // Routine completion remains available if optional user-content storage
      // is unavailable on an older or partially migrated local installation.
    }
    return _RoutineOptionalData(content, attachments);
  }

  Future<File?> _resolveRemoteAttachment(RoutineAttachment attachment) async {
    final local = await dependencies.routineAttachmentFileService.resolve(
      attachment.localRelativePath,
    );
    if (local != null) return local;
    final storagePath = attachment.storagePath;
    if (storagePath == null) return null;
    final state = await dependencies.syncLocalRepository.getState();
    final session = await dependencies.authRepository.currentSession();
    if (state.linkedUid == null ||
        session is! AuthSignedIn ||
        session.user.uid != state.linkedUid) {
      return null;
    }
    final bytes = await dependencies.routineAttachmentStorageService.download(
      uid: state.linkedUid!,
      storagePath: storagePath,
      expectedBytes: attachment.byteSize,
    );
    if (attachment.contentSha256 != null &&
        sha256.convert(bytes).toString() != attachment.contentSha256) {
      throw const FormatException('Attachment checksum does not match.');
    }
    final relative = await dependencies.routineAttachmentStorageService
        .cacheDownloaded(
          routineId: attachment.routineId,
          attachmentId: attachment.id,
          mimeType: attachment.mimeType,
          bytes: bytes,
        );
    final cached = attachment.copyWith(localRelativePath: relative);
    await dependencies.routineAttachmentRepository.applyRemote(cached);
    return dependencies.routineAttachmentFileService.resolve(relative);
  }
}

class _RoutineOptionalData {
  const _RoutineOptionalData(this.content, this.attachments);
  final RoutineContent? content;
  final List<RoutineAttachment> attachments;
}
