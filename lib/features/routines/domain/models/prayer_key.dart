enum PrayerKey {
  subuh('subuh'),
  zuhur('zuhur'),
  asar('asar'),
  maghrib('maghrib'),
  isya('isya');

  const PrayerKey(this.storageValue);
  final String storageValue;

  static PrayerKey? fromStorage(String value) => switch (value) {
    'subuh' => PrayerKey.subuh,
    'zuhur' => PrayerKey.zuhur,
    'asar' => PrayerKey.asar,
    'maghrib' => PrayerKey.maghrib,
    'isya' => PrayerKey.isya,
    _ => null,
  };
}
