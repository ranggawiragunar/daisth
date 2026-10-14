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

  static String routineTitle(String routineId, Locale locale) {
    if (routineId == 'sholat-malam') return nightPrayer(locale);
    if (routineId == 'penutup-hari') return endOfDay(locale);
    final prayer = prayerName(routineId, locale);
    return prayer.isEmpty ? '' : prayer;
  }
}
