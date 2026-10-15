import 'package:daisth/core/localization/daisth_terminology.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const english = Locale('en');
  const indonesian = Locale('id');

  group('Daisth terminology', () {
    test('keeps the three shared product terms identical', () {
      for (final locale in [english, indonesian]) {
        expect(DaisthTerminology.masjid(locale), 'Masjid');
        expect(DaisthTerminology.mushola(locale), 'Mushola');
        expect(DaisthTerminology.zikir(locale), 'Zikir');
      }
    });

    test('localizes prayer names by active language without changing IDs', () {
      expect(DaisthTerminology.prayerName('subuh', english), 'Fajr');
      expect(DaisthTerminology.prayerName('dhuha', english), 'Dhuha');
      expect(DaisthTerminology.prayerName('zuhur', english), 'Dhuhr');
      expect(DaisthTerminology.prayerName('asar', english), 'Asr');
      expect(DaisthTerminology.prayerName('maghrib', english), 'Maghrib');
      expect(DaisthTerminology.prayerName('isya', english), 'Isha');
      expect(DaisthTerminology.prayerName('subuh', indonesian), 'Subuh');
      expect(DaisthTerminology.prayerName('dhuha', indonesian), 'Dhuha');
      expect(DaisthTerminology.prayerName('zuhur', indonesian), 'Zuhur');
      expect(DaisthTerminology.prayerName('asar', indonesian), 'Asar');
      expect(DaisthTerminology.prayerName('maghrib', indonesian), 'Maghrib');
      expect(DaisthTerminology.prayerName('isya', indonesian), 'Isya');
    });

    test('localizes routine concepts and nearby-place title', () {
      expect(DaisthTerminology.nightPrayer(english), 'Night Prayer');
      expect(DaisthTerminology.endOfDay(english), 'End of Day');
      expect(DaisthTerminology.nearbyPrayerPlacesTitle(english), 'Nearby Masjid & Mushola');
      expect(DaisthTerminology.nightPrayer(indonesian), 'Sholat Malam');
      expect(DaisthTerminology.endOfDay(indonesian), 'Penutup Hari');
      expect(DaisthTerminology.nearbyPrayerPlacesTitle(indonesian), 'Masjid & Mushola Terdekat');
      expect(DaisthTerminology.routineTitle('user-custom-id', english), '');
    });

    test('localizes built-in routine descriptions and step labels by IDs', () {
      expect(DaisthTerminology.routineDescription('sholat-malam', english), 'Complete the night prayer sequence before Fajr time.');
      expect(DaisthTerminology.routineStepTitle('sholat-malam', 'taubat', 'Sholat Taubat', english), 'Taubat prayer');
      expect(DaisthTerminology.routineStepTitle('sholat-malam', 'taubat', 'Sholat Taubat', indonesian), 'Sholat Taubat');
      expect(DaisthTerminology.routineStepTitle('custom-routine', 'custom-step', 'Baca Buku QA', english), 'Baca Buku QA');
    });
  });
}
