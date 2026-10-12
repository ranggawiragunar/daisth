import '../../domain/models/reader_content.dart';
import '../../domain/models/reader_section.dart';

abstract final class ReaderDemoData {
  static final bedtimeDua = ReaderContent(
    id: 'doa-sebelum-tidur',
    title: 'Doa Sebelum Tidur',
    context: 'Dibaca ketika hendak tidur',
    sections: const [
      ReaderSection(
        arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        transliteration: 'Bismika Allahumma amutu wa ahya.',
        translation: 'Dengan nama-Mu, ya Allah, aku mati dan aku hidup.',
      ),
    ],
    sourceLabel: 'Sahih al-Bukhari 6314',
  );

  static ReaderContent? byRoute(String routineId, String contentId) {
    if (routineId == 'sholat-malam' && contentId == bedtimeDua.id) {
      return bedtimeDua;
    }
    return null;
  }
}
