import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/reader/data/catalog/reader_content_catalog.dart';

void main() {
  test('bedtime Reader IDs resolve only within Penutup Hari', () {
    final expected = {
      'ayat-kursi': 'Al-Baqarah · 2:255',
      'al-ikhlas': 'Surah 112 · 4 ayat',
      'al-falaq': 'Surah 113 · 5 ayat',
      'an-nas': 'Surah 114 · 6 ayat',
      'al-baqarah-285-286': 'Dua ayat terakhir Surah Al-Baqarah',
    };

    for (final entry in expected.entries) {
      final content = ReaderContentCatalog.byRoute('penutup-hari', entry.key);
      expect(content, isNotNull);
      expect(content!.id, entry.key);
      expect(content.context, entry.value);
      expect(content.sections, isNotEmpty);
      expect(
        content.sections.every((section) => section.arabic!.isNotEmpty),
        isTrue,
      );
      expect(
        content.sections.every(
          (section) =>
              section.transliteration?.isNotEmpty == true &&
              section.translation?.isNotEmpty == true,
        ),
        isTrue,
      );
      expect(content.sourceLabel, 'Terjemah Qur’an Kemenag · 2019');
    }

    expect(ReaderContentCatalog.byRoute('sholat-malam', 'ayat-kursi'), isNull);
    expect(ReaderContentCatalog.byRoute('penutup-hari', 'unknown'), isNull);
  });

  test('last two Al-Baqarah verses preserve separate verse sections', () {
    final content = ReaderContentCatalog.alBaqarahLastVerses;
    expect(content.id, 'al-baqarah-285-286');
    expect(content.sections.map((section) => section.heading), [
      '2:285',
      '2:286',
    ]);
  });

  test('bedtime dua reuses the verified Reader content and source', () {
    expect(
      ReaderContentCatalog.byRoute('penutup-hari', 'doa-sebelum-tidur'),
      same(ReaderContentCatalog.bedtimeDua),
    );
    expect(
      ReaderContentCatalog.bedtimeDua.sourceLabel,
      'Sahih al-Bukhari 6314',
    );
    expect(
      ReaderContentCatalog.byRoute('sholat-malam', 'doa-sebelum-tidur'),
      same(ReaderContentCatalog.bedtimeDua),
    );
  });
}
