import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../../../core/time/domain/models/calendar_day.dart';
import '../../../core/localization/daisth_localizations.dart';
import '../data/resolvers/routine_resolver.dart';
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
      return RoutineDetailScreen(
        key: ValueKey('routine-detail-${widget.routineId}'),
        routine: resolved.routine,
        noticeController: widget.noticeController,
        routineRecordRepository: widget.dependencies.routineRecordRepository,
        setRoutineStepCompletion: widget.dependencies.setRoutineStepCompletion,
        markRoutineComplete: widget.dependencies.markRoutineComplete,
        markRoutineNotToday: widget.dependencies.markRoutineNotToday,
        prayerScheduleSession: widget.historical
            ? null
            : widget.dependencies.prayerScheduleSession,
        calendarDay: widget.calendarDay,
        historical: widget.historical,
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
}
