import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/features/routines/data/demo/routine_demo_data.dart';
import 'package:istiqam/features/routines/domain/models/routine_status.dart';
import 'package:istiqam/features/routines/presentation/view_models/routine_detail_view_model.dart';

void main() {
  test(
    'Sholat Malam starts partial and supports toggle, undo, and completion',
    () {
      final viewModel = RoutineDetailViewModel(RoutineDemoData.sholatMalam);
      addTearDown(viewModel.dispose);

      expect(viewModel.status, RoutineStatus.partial);
      expect(viewModel.completedRequiredCount, 2);

      viewModel.toggleStep('hajat');
      expect(viewModel.completedRequiredCount, 3);
      viewModel.undoStep();
      expect(viewModel.completedRequiredCount, 2);

      viewModel.markAllRemaining();
      expect(viewModel.status, RoutineStatus.completed);
    },
  );

  test('Dhuha minimum completes while optional rakaat remain toggleable', () {
    final viewModel = RoutineDetailViewModel(RoutineDemoData.dhuha);
    addTearDown(viewModel.dispose);

    expect(viewModel.status, RoutineStatus.pending);
    expect(viewModel.requiredCount, 1);
    viewModel.toggleStep('dhuha-minimum');
    expect(viewModel.status, RoutineStatus.completed);
    expect(viewModel.completedRequiredCount, 1);

    viewModel.toggleStep('dhuha-extra');
    expect(viewModel.status, RoutineStatus.completed);
    expect(viewModel.completedRakaat, 4);
  });

  test('Zuhur is mandatory and optional dhikr does not block completion', () {
    final viewModel = RoutineDetailViewModel(RoutineDemoData.zuhur);
    addTearDown(viewModel.dispose);

    expect(viewModel.isOptional, isFalse);
    expect(viewModel.markNotToday(), isFalse);
    viewModel.toggleStep('zuhur');
    expect(viewModel.status, RoutineStatus.completed);
    viewModel.toggleStep('post-prayer-dhikr');
    expect(viewModel.status, RoutineStatus.completed);
  });

  test('post-prayer dhikr is optional and completes by stable step id', () {
    final viewModel = RoutineDetailViewModel(RoutineDemoData.zuhur);
    addTearDown(viewModel.dispose);

    viewModel.markRequiredStepsDone();
    expect(viewModel.status, RoutineStatus.completed);
    expect(viewModel.completeOptionalStep('post-prayer-dhikr'), isTrue);
    expect(viewModel.status, RoutineStatus.completed);
    expect(viewModel.steps.last.completed, isTrue);
    expect(viewModel.completeOptionalStep('post-prayer-dhikr'), isFalse);
  });

  test('optional routine can be Not Today with or without a reason', () {
    final withoutReason = RoutineDetailViewModel(RoutineDemoData.dhuha);
    addTearDown(withoutReason.dispose);
    expect(withoutReason.markNotToday(), isTrue);
    expect(withoutReason.status, RoutineStatus.notToday);
    expect(withoutReason.notTodayReason, isNull);

    final withReason = RoutineDetailViewModel(RoutineDemoData.sholatMalam);
    addTearDown(withReason.dispose);
    expect(withReason.markNotToday(reason: 'Bepergian'), isTrue);
    expect(withReason.status, RoutineStatus.notToday);
    expect(withReason.notTodayReason, 'Bepergian');
  });
}
