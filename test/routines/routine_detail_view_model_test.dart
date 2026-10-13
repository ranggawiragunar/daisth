import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/routine.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_not_today_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';
import 'package:daisth/features/routines/presentation/view_models/routine_detail_view_model.dart';

import '../support/test_persistence.dart';

void main() {
  late TestPersistence persistence;

  setUp(() async {
    persistence = await TestPersistence.create();
  });
  tearDown(() => persistence.dispose());

  test(
    'Sholat Malam starts unrecorded and supports toggle, undo, completion',
    () async {
      final viewModel = _viewModel(RoutineDemoData.sholatMalam, persistence);
      addTearDown(viewModel.dispose);
      await viewModel.initialize();

      expect(viewModel.status, RoutineStatus.pending);
      expect(viewModel.completedRequiredCount, 0);

      await viewModel.toggleStep('tahajud');
      expect(viewModel.status, RoutineStatus.partial);
      expect(viewModel.completedRequiredCount, 1);
      final restored = _viewModel(RoutineDemoData.sholatMalam, persistence);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.status, RoutineStatus.partial);
      expect(
        restored.steps.singleWhere((step) => step.id == 'tahajud').completed,
        isTrue,
      );
      await restored.toggleStep('tahajud');
      expect(restored.status, RoutineStatus.pending);

      await restored.markAllRemaining();
      expect(restored.status, RoutineStatus.completed);
    },
  );

  test(
    'Dhuha minimum completes while optional rakaat remain toggleable',
    () async {
      final viewModel = _viewModel(RoutineDemoData.dhuha, persistence);
      addTearDown(viewModel.dispose);
      await viewModel.initialize();

      expect(viewModel.status, RoutineStatus.pending);
      expect(viewModel.requiredCount, 1);
      await viewModel.toggleStep('dhuha-minimum');
      expect(viewModel.status, RoutineStatus.completed);
      expect(viewModel.completedRequiredCount, 1);

      await viewModel.toggleStep('dhuha-extra');
      expect(viewModel.status, RoutineStatus.completed);
      expect(viewModel.completedRakaat, 4);
    },
  );

  test(
    'Zuhur is mandatory and optional dhikr does not block completion',
    () async {
      final viewModel = _viewModel(RoutineDemoData.zuhur, persistence);
      addTearDown(viewModel.dispose);
      await viewModel.initialize();

      expect(viewModel.isOptional, isFalse);
      expect(await viewModel.markNotToday(), isFalse);
      await viewModel.toggleStep('zuhur');
      expect(viewModel.status, RoutineStatus.completed);
      await viewModel.toggleStep('post-prayer-dhikr');
      expect(viewModel.status, RoutineStatus.completed);
    },
  );

  test('optional routine can be Not Today with or without a reason', () async {
    final withoutReason = _viewModel(RoutineDemoData.dhuha, persistence);
    addTearDown(withoutReason.dispose);
    await withoutReason.initialize();
    expect(await withoutReason.markNotToday(), isTrue);
    expect(withoutReason.status, RoutineStatus.notToday);
    expect(withoutReason.notTodayReason, isNull);

    final withReason = _viewModel(RoutineDemoData.sholatMalam, persistence);
    addTearDown(withReason.dispose);
    await withReason.initialize();
    expect(await withReason.markNotToday(reason: 'Bepergian'), isTrue);
    expect(withReason.status, RoutineStatus.notToday);
    expect(withReason.notTodayReason, 'Bepergian');
  });
}

RoutineDetailViewModel _viewModel(
  Routine routine,
  TestPersistence persistence,
) {
  final repository = persistence.routineRecords;
  final resolver = const ResolveRoutineStatusUseCase();
  return RoutineDetailViewModel(
    routine: routine,
    repository: repository,
    setStepCompletion: SetRoutineStepCompletionUseCase(repository: repository),
    markRoutineComplete: MarkRoutineCompleteUseCase(
      repository: repository,
      resolveStatus: resolver,
    ),
    markRoutineNotToday: MarkRoutineNotTodayUseCase(repository),
    clock: () => DateTime(2026, 10, 13, 10),
  );
}
