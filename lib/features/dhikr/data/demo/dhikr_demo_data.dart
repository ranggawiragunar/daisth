import '../../domain/models/dhikr_item.dart';
import '../../domain/models/dhikr_sequence.dart';

abstract final class DhikrDemoData {
  static final postPrayer = DhikrSequence(
    id: 'post-prayer',
    title: 'Dzikir Setelah Sholat',
    context: 'Setelah sholat fardhu',
    sourceLabel: 'Sahih Muslim 597a',
    items: const [
      DhikrItem(
        id: 'subhanallah',
        title: 'Subhanallah',
        arabic: 'سُبْحَانَ اللَّهِ',
        transliteration: 'Subhanallah',
        targetCount: 33,
      ),
      DhikrItem(
        id: 'alhamdulillah',
        title: 'Alhamdulillah',
        arabic: 'الْحَمْدُ لِلَّهِ',
        transliteration: 'Alhamdulillah',
        targetCount: 33,
      ),
      DhikrItem(
        id: 'allahu-akbar',
        title: 'Allahu Akbar',
        arabic: 'اللَّهُ أَكْبَرُ',
        transliteration: 'Allahu Akbar',
        targetCount: 33,
      ),
      DhikrItem(
        id: 'tahlil-closing',
        title: 'Penutup',
        arabic:
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration:
            "La ilaha illallahu wahdahu la sharika lahu,\n"
            'lahul-mulku wa lahul-hamdu,\n'
            "wa huwa 'ala kulli shay'in qadir.",
        targetCount: 1,
      ),
    ],
  );

  static DhikrSequence? byRoute(String routineId, String dhikrId) {
    if (const {
          'subuh',
          'zuhur',
          'asar',
          'maghrib',
          'isya',
        }.contains(routineId) &&
        dhikrId == postPrayer.id) {
      return postPrayer;
    }
    return null;
  }
}
