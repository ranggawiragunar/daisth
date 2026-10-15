import 'dart:ui' show Locale;

/// Product terminology for the supported Indonesian and English interfaces.
///
/// Stable identifiers and user-authored routine names are deliberately kept
/// outside this presentation-only mapping.
abstract final class DaisthTerminology {
  static const supportedLocales = [Locale('en'), Locale('id')];

  static String languageCode(Locale locale) =>
      locale.languageCode.toLowerCase() == 'id' ? 'id' : 'en';

  static String masjid(Locale locale) => 'Masjid';
  static String mushola(Locale locale) => 'Mushola';
  static String zikir(Locale locale) => 'Zikir';

  static String prayerName(String routineId, Locale locale) {
    final english = languageCode(locale) == 'en';
    return switch (routineId) {
      'subuh' => english ? 'Fajr' : 'Subuh',
      'dhuha' => english ? 'Duha' : 'Dhuha',
      'zuhur' => english ? 'Dhuhr' : 'Zuhur',
      'asar' => english ? 'Asr' : 'Asar',
      'maghrib' => 'Maghrib',
      'isya' => english ? 'Isha' : 'Isya',
      _ => '',
    };
  }

  static String nightPrayer(Locale locale) =>
      languageCode(locale) == 'en' ? 'Night Prayer' : 'Sholat Malam';

  static String endOfDay(Locale locale) =>
      languageCode(locale) == 'en' ? 'End of Day' : 'Penutup Hari';

  static String nearbyPrayerPlacesTitle(Locale locale) =>
      languageCode(locale) == 'en'
      ? 'Nearby Masjid & Mushola'
      : 'Masjid & Mushola Terdekat';

  static String nearbyPrayerPlacesSubtitle(Locale locale) =>
      languageCode(locale) == 'en'
      ? 'Find Masjid or Mushola near you'
      : 'Cari Masjid atau Mushola di sekitarmu';

  static String postPrayerZikirTitle(Locale locale) =>
      languageCode(locale) == 'en'
      ? 'Zikir after prayer'
      : 'Zikir setelah salat';

  static String dhikrSequenceContext(
    String sequenceId,
    String fallback,
    Locale locale,
  ) {
    if (sequenceId != 'post-prayer') return fallback;
    return languageCode(locale) == 'en'
        ? 'After each obligatory prayer'
        : 'Setelah sholat fardhu';
  }

  static String dhikrItemTitle(String itemId, String fallback, Locale locale) {
    if (itemId == 'tahlil-closing' && languageCode(locale) == 'en') {
      return 'Closing';
    }
    if (itemId == 'tahlil-closing' && languageCode(locale) == 'id') {
      return 'Penutup';
    }
    return fallback;
  }

  static String routineTitle(String routineId, Locale locale) {
    if (routineId == 'sholat-malam') return nightPrayer(locale);
    if (routineId == 'penutup-hari') return endOfDay(locale);
    final prayer = prayerName(routineId, locale);
    return prayer.isEmpty ? '' : prayer;
  }

  static String routineDescription(String routineId, Locale locale) {
    if (languageCode(locale) != 'en') return '';
    return switch (routineId) {
      'sholat-malam' => 'Complete the night prayer sequence before Fajr time.',
      'dhuha' => 'Aim for 4 rakaat if possible. The minimum is 2 rakaat.',
      'subuh' => 'Perform the Fajr prayer.',
      'zuhur' => 'Perform the Dhuhr prayer.',
      'asar' => 'Perform the Asr prayer.',
      'maghrib' => 'Perform the Maghrib prayer.',
      'isya' => 'Perform the Isha prayer.',
      'penutup-hari' =>
        'Readings before sleep. Complete what feels right tonight.',
      _ => '',
    };
  }

  static String routineContextLabel(
    String routineId,
    String fallback,
    Locale locale,
  ) {
    final english = languageCode(locale) == 'en';
    return switch (routineId) {
      'sholat-malam' => english ? 'Before Fajr' : 'Sebelum Subuh',
      'dhuha' => english ? 'Window open' : 'Waktu tersedia',
      'penutup-hari' => english ? 'Before sleep' : 'Sebelum tidur',
      _ => fallback,
    };
  }

  static String routineStepTitle(
    String routineId,
    String stepId,
    String fallback,
    Locale locale,
  ) {
    if (languageCode(locale) != 'en') return fallback;
    return switch ((routineId, stepId)) {
      ('sholat-malam', 'taubat') => 'Taubat prayer',
      ('sholat-malam', 'hajat') => 'Hajat prayer',
      ('dhuha', 'dhuha-extra') => 'Additional 2 rakaat',
      ('dhuha', 'dhuha-minimum') => '2 rakaat',
      ('subuh', 'qabliyah-subuh') => 'Qabliyah Fajr',
      ('subuh', 'subuh') => 'Fajr prayer',
      ('zuhur', 'zuhur') => 'Dhuhr prayer',
      ('asar', 'asar') => 'Asr prayer',
      ('maghrib', 'maghrib') => 'Maghrib prayer',
      ('isya', 'isya') => 'Isha prayer',
      _ => fallback,
    };
  }

  static String routineStepSubtitle(
    String routineId,
    String stepId,
    String fallback,
    Locale locale,
  ) {
    if (languageCode(locale) != 'en') return fallback;
    return switch ((routineId, stepId)) {
      ('dhuha', 'dhuha-minimum') => 'Start with what feels manageable',
      ('dhuha', 'dhuha-extra') => 'Continue toward 4 rakaat',
      ('zuhur', 'post-prayer-dhikr') => 'You can continue after prayer',
      ('subuh', 'post-prayer-dhikr') => 'You can continue after prayer',
      ('asar', 'post-prayer-dhikr') => 'You can continue after prayer',
      ('maghrib', 'post-prayer-dhikr') => 'You can continue after prayer',
      ('isya', 'post-prayer-dhikr') => 'You can continue after prayer',
      ('penutup-hari', 'al-baqarah-285-286') => 'The last two verses',
      _ => fallback,
    };
  }

  static String? routineStepGuidanceTitle(
    String routineId,
    String stepId,
    String? fallback,
    Locale locale,
  ) {
    if (routineId == 'dhuha' && stepId == 'dhuha-minimum') {
      return languageCode(locale) == 'en'
          ? 'Duha Prayer Guide'
          : (fallback ?? 'Panduan Sholat Dhuha');
    }
    if (stepId == 'post-prayer-dhikr' &&
        const {
          'subuh',
          'zuhur',
          'asar',
          'maghrib',
          'isya',
        }.contains(routineId)) {
      return postPrayerZikirTitle(locale);
    }
    return fallback;
  }

  static String? routineStepBadge(String? fallback, Locale locale) {
    if (fallback == null) return null;
    if (fallback == 'Optional' || fallback == 'Opsional') {
      return languageCode(locale) == 'en' ? 'Optional' : 'Opsional';
    }
    return fallback;
  }

  static String? routineStepSectionTitle(
    String routineId,
    String? fallback,
    Locale locale,
  ) {
    if (fallback == null || routineId != 'penutup-hari') return fallback;
    if (languageCode(locale) != 'en') return fallback;
    return switch (fallback) {
      'Persiapan' => 'Preparation',
      'Bacaan' => 'Readings',
      'Penutup' => 'Closing',
      _ => fallback,
    };
  }
}
