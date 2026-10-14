import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/reader/data/catalog/reader_content_catalog.dart';
import 'package:daisth/features/reader/domain/models/reader_content.dart';

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
      isNull,
    );
  });

  test('Taubat reading contains only the two selected supplications', () {
    final content = ReaderContentCatalog.byRoute(
      'sholat-malam',
      'taubat-after-prayer',
    )!;
    expect(content.sections.map((section) => section.heading), [
      'Istighfar',
      'Sayyidul Istighfar',
    ]);
    expect(
      content.sections.first.arabic,
      'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    );
    expect(
      content.sections.first.transliteration,
      'Astaghfirullāhal-‘aẓīma wa atūbu ilaih.',
    );
    expect(content.sections.last.arabic, contains('اللَّهُمَّ أَنْتَ رَبِّي'));
    expect(
      content.sections.last.arabic,
      contains('فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ'),
    );
    expect(content.sections.last.sourceLabel, 'Sahih al-Bukhari 6306');
    expect(content.sections.last.translationEn, contains('You are my Lord'));
    expect(content.titleFor('en'), 'After Taubat Prayer');
    expect(content.sections.last.headingFor('en'), 'Sayyidul Istighfar');
    expect(
      content.sections.last.translationFor('en'),
      contains('forgives sins'),
    );

    final allText = _allContentText(content).toLowerCase();
    for (final excluded in [
      'niat',
      'rakaat',
      'doa pribadi',
      'hal yang perlu diperhatikan',
      '.png',
      '.jpg',
    ]) {
      expect(allText, isNot(contains(excluded)));
    }
  });

  test('Hajat reading contains only the selected praise and dua', () {
    final content = ReaderContentCatalog.byRoute(
      'sholat-malam',
      'hajat-after-prayer',
    )!;
    expect(content.sections.map((section) => section.heading), [
      'Pujian & Sholawat',
      'Doa Hajat',
    ]);
    expect(
      content.sections.first.arabic,
      contains('سُبْحَانَ الَّذِي لَبِسَ الْعِزَّ'),
    );
    expect(content.sections.first.sourceLabel, isNull);
    expect(content.sections.first.note, isNull);
    expect(
      content.sections.last.arabic,
      contains('لَا إِلَهَ إِلَّا اللَّهُ الْحَلِيمُ الْكَرِيمُ'),
    );
    expect(
      content.sections.last.arabic,
      contains('يَا أَرْحَمَ الرَّاحِمِينَ'),
    );
    expect(content.sections.last.sourceLabel, "Jami' at-Tirmidhi 479");
    expect(
      content.sections.last.note,
      'Sanad riwayat ini memiliki catatan kelemahan.',
    );
    expect(
      content.sections.last.noteEn,
      'The chain of this narration has noted weakness.',
    );
    expect(content.titleFor('en'), 'After Hajat Prayer');
    expect(content.sections.first.headingFor('en'), 'Praise & Sholawat');
    expect(content.sections.last.translationFor('en'), contains('Forbearing'));

    final allText = _allContentText(content).toLowerCase();
    for (final excluded in [
      'niat',
      'rakaat',
      'al-fatihah',
      'al-ikhlas',
      'ayat kursi',
      'tata cara',
      'doa pribadi',
      'sahih al-bukhari',
      'sahih muslim',
      '.png',
      '.jpg',
    ]) {
      expect(allText, isNot(contains(excluded)));
    }
    expect(
      ReaderContentCatalog.byRoute('penutup-hari', 'taubat-after-prayer'),
      isNull,
    );
    expect(
      ReaderContentCatalog.byRoute('penutup-hari', 'hajat-after-prayer'),
      isNull,
    );
  });
}

String _allContentText(ReaderContent content) => [
  content.id,
  content.title,
  content.titleEn,
  content.context,
  content.contextEn,
  content.sourceLabel,
  content.sourceLabelEn,
  for (final section in content.sections) ...[
    section.heading,
    section.headingEn,
    section.arabic,
    section.transliteration,
    section.translation,
    section.translationEn,
    section.sourceLabel,
    section.sourceLabelEn,
    section.note,
    section.noteEn,
  ],
].whereType<String>().join('\n');
