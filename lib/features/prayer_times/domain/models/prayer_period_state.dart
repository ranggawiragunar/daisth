import 'prayer_name.dart';

class PrayerPeriodState {
  const PrayerPeriodState({
    required this.currentPrayer,
    required this.nextPrayer,
  });

  final PrayerName? currentPrayer;
  final PrayerName? nextPrayer;

  PrayerName get focusPrayer => currentPrayer ?? nextPrayer!;

  String get focusLabel => currentPrayer == null ? 'Berikutnya' : 'Waktunya';
}
