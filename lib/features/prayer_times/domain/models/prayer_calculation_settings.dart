enum PrayerCalculationMethod { indonesiaKemenag }

enum PrayerAsrMethod { shafi, hanafi }

class PrayerCalculationSettings {
  const PrayerCalculationSettings({
    this.method = PrayerCalculationMethod.indonesiaKemenag,
    this.asrMethod = PrayerAsrMethod.shafi,
  });

  static const defaultSettings = PrayerCalculationSettings();

  final PrayerCalculationMethod method;
  final PrayerAsrMethod asrMethod;
}
