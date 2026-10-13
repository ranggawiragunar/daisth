import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/dhikr/data/demo/dhikr_demo_data.dart';
import 'package:daisth/features/dhikr/presentation/view_models/dhikr_counter_view_model.dart';

void main() {
  test('starts with Subhanallah at zero', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    expect(viewModel.currentItem.id, 'subhanallah');
    expect(viewModel.currentItemCount, 0);
    expect(viewModel.totalCount, 0);
    expect(viewModel.isCompleted, isFalse);
  });

  test('increments without passing a target and auto-advances', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    for (var count = 0; count < 33; count++) {
      viewModel.increment();
    }
    expect(viewModel.currentItem.id, 'alhamdulillah');
    expect(viewModel.counts.first, 33);
    expect(viewModel.currentItemCount, 0);
    expect(viewModel.completedItemCount, 1);

    viewModel.increment();
    expect(viewModel.counts.first, 33);
    expect(viewModel.currentItemCount, 1);
  });

  test('sequence advances through all 33/33/33/1 targets', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    for (final expectedId in [
      'subhanallah',
      'alhamdulillah',
      'allahu-akbar',
      'tahlil-closing',
    ]) {
      expect(viewModel.currentItem.id, expectedId);
      final target = viewModel.currentItem.targetCount;
      for (var count = 0; count < target; count++) {
        viewModel.increment();
      }
    }

    expect(viewModel.isCompleted, isTrue);
    expect(viewModel.counts, [33, 33, 33, 1]);
    expect(viewModel.totalCount, 100);
    expect(viewModel.completedItemCount, 4);
  });

  test('undo decrements the active count', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    viewModel.increment();
    viewModel.increment();
    viewModel.undo();

    expect(viewModel.currentItem.id, 'subhanallah');
    expect(viewModel.currentItemCount, 1);
  });

  test('undo after auto-advance returns to the previous target minus one', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    for (var count = 0; count < 33; count++) {
      viewModel.increment();
    }
    viewModel.undo();

    expect(viewModel.currentItem.id, 'subhanallah');
    expect(viewModel.currentItemCount, 32);
    expect(viewModel.counts[1], 0);
    expect(viewModel.isCompleted, isFalse);
  });

  test('undo on sequence completion reopens the final count', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    for (final item in DhikrDemoData.postPrayer.items) {
      for (var count = 0; count < item.targetCount; count++) {
        viewModel.increment();
      }
    }
    viewModel.undo();

    expect(viewModel.isCompleted, isFalse);
    expect(viewModel.currentItem.id, 'tahlil-closing');
    expect(viewModel.currentItemCount, 0);
  });

  test('reset returns all progress to the initial state', () {
    final viewModel = DhikrCounterViewModel(DhikrDemoData.postPrayer);
    addTearDown(viewModel.dispose);

    for (var count = 0; count < 34; count++) {
      viewModel.increment();
    }
    viewModel.reset();

    expect(viewModel.currentItem.id, 'subhanallah');
    expect(viewModel.currentItemCount, 0);
    expect(viewModel.counts, [0, 0, 0, 0]);
    expect(viewModel.totalCount, 0);
    expect(viewModel.canUndo, isFalse);
    expect(viewModel.isCompleted, isFalse);
  });
}
