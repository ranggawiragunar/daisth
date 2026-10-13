import 'package:flutter/foundation.dart';

import '../../../../core/time/domain/models/calendar_day.dart';
import '../../domain/models/daily_reflection.dart';
import '../../domain/models/reflection_rhythm.dart';
import '../../domain/use_cases/clear_daily_reflection_use_case.dart';
import '../../domain/use_cases/get_daily_reflection_use_case.dart';
import '../../domain/use_cases/save_daily_reflection_use_case.dart';

class ReflectionViewModel extends ChangeNotifier {
  ReflectionViewModel({
    required this.day,
    required this.getReflection,
    required this.saveReflection,
    required this.clearReflection,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CalendarDay day;
  final GetDailyReflectionUseCase getReflection;
  final SaveDailyReflectionUseCase saveReflection;
  final ClearDailyReflectionUseCase clearReflection;
  final DateTime Function() _clock;

  DailyReflection? savedReflection;
  ReflectionRhythm? selectedRhythm;
  String note = '';
  bool isLoading = true;
  bool isSaving = false;
  bool rhythmError = false;
  bool noteError = false;
  String? errorMessage;
  ReflectionRhythm? _initialRhythm;
  String _initialNote = '';

  bool get isDirty =>
      !isLoading && (selectedRhythm != _initialRhythm || note != _initialNote);

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      _applySaved(await getReflection(day));
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Refleksi belum dapat dimuat. Coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectRhythm(ReflectionRhythm rhythm) {
    selectedRhythm = rhythm;
    rhythmError = false;
    notifyListeners();
  }

  void updateNote(String value) {
    note = value;
    noteError = value.length > SaveDailyReflectionUseCase.maxNoteLength;
    notifyListeners();
  }

  Future<bool> save() async {
    if (selectedRhythm == null) {
      rhythmError = true;
      notifyListeners();
      return false;
    }
    if (note.length > SaveDailyReflectionUseCase.maxNoteLength) {
      noteError = true;
      notifyListeners();
      return false;
    }
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final saved = await saveReflection(
        day: day,
        rhythm: selectedRhythm!,
        note: note,
        now: _clock(),
      );
      _applySaved(saved);
      return true;
    } catch (_) {
      errorMessage = 'Refleksi belum dapat disimpan. Coba lagi.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> clear() async {
    if (savedReflection == null) return true;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await clearReflection(day);
      _applySaved(null);
      return true;
    } catch (_) {
      errorMessage = 'Refleksi belum dapat dihapus. Coba lagi.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _applySaved(DailyReflection? reflection) {
    savedReflection = reflection;
    selectedRhythm = reflection?.rhythm;
    note = reflection?.note ?? '';
    _initialRhythm = selectedRhythm;
    _initialNote = note;
    rhythmError = false;
    noteError = false;
  }
}
