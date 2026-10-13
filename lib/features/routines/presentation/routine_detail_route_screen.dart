import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';
import '../../../core/design_system/components/daisth_notice_controller.dart';
import '../data/resolvers/routine_resolver.dart';
import 'routine_detail_screen.dart';

class RoutineDetailRouteScreen extends StatefulWidget {
  const RoutineDetailRouteScreen({
    required this.routineId,
    required this.dependencies,
    required this.noticeController,
    super.key,
  });

  final String routineId;
  final AppDependencies dependencies;
  final DaisthNoticeController noticeController;

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
        return const Scaffold(body: Center(child: Text('Memuat routine...')));
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
        prayerScheduleSession: widget.dependencies.prayerScheduleSession,
      );
    },
  );

  String get routineId => widget.routineId;
  AppDependencies get dependencies => widget.dependencies;

  Future<ResolvedRoutine?> _load() async {
    await dependencies.ensureRoutineDefinitionsReady();
    return dependencies.routineResolver.resolve(routineId);
  }
}
