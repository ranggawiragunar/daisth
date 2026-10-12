import 'package:flutter/foundation.dart';

import '../../domain/models/dhikr_item.dart';
import '../../domain/models/dhikr_sequence.dart';

class DhikrCounterViewModel extends ChangeNotifier {
  DhikrCounterViewModel(this.sequence)
    : _counts = List.filled(sequence.items.length, 0);

  final DhikrSequence sequence;
  final List<int> _counts;
  int _currentItemIndex = 0;
  bool _sequenceCompleted = false;
  bool _lastCountAdvancedItem = false;

  int get currentItemIndex => _currentItemIndex;
  int get currentItemCount => _counts[_currentItemIndex];
  bool get isCompleted => _sequenceCompleted;
  bool get hasProgress => totalCount > 0;
  bool get canUndo => hasProgress;
  int get totalCount => _counts.fold(0, (total, count) => total + count);
  int get totalTarget =>
      sequence.items.fold(0, (total, item) => total + item.targetCount);
  List<int> get counts => List.unmodifiable(_counts);
  int get completedItemCount => List.generate(
    sequence.items.length,
    (index) => _counts[index] >= sequence.items[index].targetCount ? 1 : 0,
  ).fold(0, (total, completed) => total + completed);

  DhikrItem get currentItem => sequence.items[_currentItemIndex];

  void increment() {
    if (_sequenceCompleted) return;
    _lastCountAdvancedItem = false;
    final item = currentItem;
    if (_counts[_currentItemIndex] >= item.targetCount) return;

    _counts[_currentItemIndex]++;
    if (_counts[_currentItemIndex] == item.targetCount) {
      if (_currentItemIndex == sequence.items.length - 1) {
        _sequenceCompleted = true;
      } else {
        _currentItemIndex++;
        _lastCountAdvancedItem = true;
      }
    }
    notifyListeners();
  }

  void undo() {
    if (!hasProgress) return;
    if (_lastCountAdvancedItem) {
      _currentItemIndex--;
      _counts[_currentItemIndex] =
          sequence.items[_currentItemIndex].targetCount - 1;
      _lastCountAdvancedItem = false;
      _sequenceCompleted = false;
    } else if (_counts[_currentItemIndex] > 0) {
      _counts[_currentItemIndex]--;
      _sequenceCompleted = false;
    } else {
      return;
    }
    notifyListeners();
  }

  void reset() {
    for (var index = 0; index < _counts.length; index++) {
      _counts[index] = 0;
    }
    _currentItemIndex = 0;
    _sequenceCompleted = false;
    _lastCountAdvancedItem = false;
    notifyListeners();
  }
}
