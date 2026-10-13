import '../../domain/models/reader_content.dart';
import '../../domain/models/reader_section.dart';

/// Verified local Reader text used by the built-in bedtime routine.
/// Qur'an transliteration and Indonesian translation follow Qur'an Kemenag
/// (Mushaf Standar Indonesia, translation edition 2019).
abstract final class ReaderContentCatalog {
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

  static final ayatKursi = ReaderContent(
    id: 'ayat-kursi',
    title: 'Ayat Kursi',
    context: 'Al-Baqarah · 2:255',
    sections: const [
      ReaderSection(
        heading: '255',
        arabic:
            'اَللّٰهُ لَآ اِلٰهَ اِلَّا هُوَۚ اَلْحَيُّ الْقَيُّوْمُ ەۚ '
            'لَا تَأْخُذُهٗ سِنَةٌ وَّلَا نَوْمٌۗ لَهٗ مَا فِى السَّمٰوٰتِ '
            'وَمَا فِى الْاَرْضِۗ مَنْ ذَا الَّذِيْ يَشْفَعُ عِنْدَهٗٓ '
            'اِلَّا بِاِذْنِهٖۗ يَعْلَمُ مَا بَيْنَ اَيْدِيْهِمْ وَمَا '
            'خَلْفَهُمْۚ وَلَا يُحِيْطُوْنَ بِشَيْءٍ مِّنْ عِلْمِهٖٓ '
            'اِلَّا بِمَا شَاۤءَۚ وَسِعَ كُرْسِيُّهُ السَّمٰوٰتِ وَالْاَرْضَۚ '
            'وَلَا يَـُٔوْدُهٗ حِفْظُهُمَاۚ وَهُوَ الْعَلِيُّ الْعَظِيْمُ',
        transliteration:
            'Allāhu lā ilāha illā huw(a), al-ḥayyul-qayyūm(u), lā ta’khużuhū '
            'sinatuw wa lā naum(un), lahū mā fis-samāwāti wa mā fil-arḍ(i), '
            'man żal-lażī yasyfa‘u ‘indahū illā bi’iżnih(ī), ya‘lamu mā baina '
            'aidīhim wa mā khalfahum, wa lā yuḥīṭūna bisyai’im min ‘ilmihī '
            'illā bimā syā’(a), wasi‘a kursiyyuhus-samāwāti wal-arḍ(a), wa lā '
            'ya’ūduhū ḥifẓuhumā, wa huwal-‘aliyyul-‘aẓīm(u).',
        translation:
            'Allah, tidak ada tuhan selain Dia, Yang Maha Hidup lagi terus-menerus '
            'mengurus (makhluk-Nya). Dia tidak dilanda oleh kantuk dan tidak '
            '(pula) oleh tidur. Milik-Nyalah apa yang ada di langit dan apa '
            'yang ada di bumi. Tidak ada yang dapat memberi syafaat di sisi-Nya '
            'tanpa izin-Nya. Dia mengetahui apa yang ada di hadapan mereka dan '
            'apa yang ada di belakang mereka. Mereka tidak mengetahui sesuatu '
            'apa pun dari ilmu-Nya, kecuali apa yang Dia kehendaki. Kursi-Nya '
            '(ilmu dan kekuasaan-Nya) meliputi langit dan bumi. Dia tidak merasa '
            'berat memelihara keduanya. Dialah yang Maha Tinggi lagi Maha Agung.',
      ),
    ],
    sourceLabel: 'Terjemah Qur’an Kemenag · 2019',
  );

  static final alIkhlas = ReaderContent(
    id: 'al-ikhlas',
    title: 'Al-Ikhlas',
    context: 'Surah 112 · 4 ayat',
    sections: const [
      _basmala,
      ReaderSection(
        heading: '112:1',
        arabic: 'قُلْ هُوَ اللّٰهُ اَحَدٌۚ',
        transliteration: 'Qul huwallāhu aḥad(un).',
        translation:
            'Katakanlah (Nabi Muhammad), “Dialah Allah Yang Maha Esa.”',
      ),
      ReaderSection(
        heading: '112:2',
        arabic: 'اَللّٰهُ الصَّمَدُۚ',
        transliteration: 'Allāhuṣ-ṣamad(u).',
        translation: 'Allah tempat meminta segala sesuatu.',
      ),
      ReaderSection(
        heading: '112:3',
        arabic: 'لَمْ يَلِدْ وَلَمْ يُوْلَدْۙ',
        transliteration: 'Lam yalid wa lam yūlad.',
        translation: 'Dia tidak beranak dan tidak pula diperanakkan.',
      ),
      ReaderSection(
        heading: '112:4',
        arabic: 'وَلَمْ يَكُنْ لَّهٗ كُفُوًا اَحَدٌ ࣖ',
        transliteration: 'Wa lam yakul lahū kufuwan aḥad(un).',
        translation: 'Serta tidak ada sesuatu pun yang setara dengan-Nya.',
      ),
    ],
    sourceLabel: 'Terjemah Qur’an Kemenag · 2019',
  );

  static final alFalaq = ReaderContent(
    id: 'al-falaq',
    title: 'Al-Falaq',
    context: 'Surah 113 · 5 ayat',
    sections: const [
      _basmala,
      ReaderSection(
        heading: '113:1',
        arabic: 'قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِۙ',
        transliteration: 'Qul a‘ūżu birabbil-falaq(i).',
        translation:
            'Katakanlah (Nabi Muhammad), “Aku berlindung kepada Tuhan yang (menjaga) fajar (subuh),”',
      ),
      ReaderSection(
        heading: '113:2',
        arabic: 'مِنْ شَرِّ مَا خَلَقَۙ',
        transliteration: 'Min syarri mā khalaq(a).',
        translation: 'dari kejahatan (makhluk yang) Dia ciptakan,',
      ),
      ReaderSection(
        heading: '113:3',
        arabic: 'وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ',
        transliteration: 'Wa min syarri gāsiqin iżā waqab(a).',
        translation: 'dari kejahatan malam apabila telah gelap gulita,',
      ),
      ReaderSection(
        heading: '113:4',
        arabic: 'وَمِنْ شَرِّ النَّفّٰثٰتِ فِى الْعُقَدِۙ',
        transliteration: 'Wa min syarrin-naffāṡāti fil-‘uqad(i).',
        translation:
            'dari kejahatan perempuan-perempuan (penyihir) yang meniup pada buhul-buhul (talinya),',
      ),
      ReaderSection(
        heading: '113:5',
        arabic: 'وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ ࣖ',
        transliteration: 'Wa min syarri ḥāsidin iżā ḥasad(a).',
        translation:
            'dan dari kejahatan orang yang dengki apabila dia dengki.”',
      ),
    ],
    sourceLabel: 'Terjemah Qur’an Kemenag · 2019',
  );

  static final anNas = ReaderContent(
    id: 'an-nas',
    title: 'An-Nas',
    context: 'Surah 114 · 6 ayat',
    sections: const [
      _basmala,
      ReaderSection(
        heading: '114:1',
        arabic: 'قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ',
        transliteration: 'Qul a‘ūżu birabbin-nās(i).',
        translation:
            'Katakanlah (Nabi Muhammad), “Aku berlindung kepada Tuhan manusia,',
      ),
      ReaderSection(
        heading: '114:2',
        arabic: 'مَلِكِ النَّاسِۙ',
        transliteration: 'Malikin-nās(i).',
        translation: 'raja manusia,',
      ),
      ReaderSection(
        heading: '114:3',
        arabic: 'اِلٰهِ النَّاسِۙ',
        transliteration: 'Ilāhin-nās(i).',
        translation: 'sembahan manusia,',
      ),
      ReaderSection(
        heading: '114:4',
        arabic: 'مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ',
        transliteration: 'Min syarril-waswāsil-khannās(i).',
        translation: 'dari kejahatan (setan) pembisik yang bersembunyi,',
      ),
      ReaderSection(
        heading: '114:5',
        arabic: 'الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ',
        transliteration: 'Allażī yuwaswisu fī ṣudūrin-nās(i).',
        translation: 'yang membisikkan (kejahatan) ke dalam dada manusia,',
      ),
      ReaderSection(
        heading: '114:6',
        arabic: 'مِنَ الْجِنَّةِ وَالنَّاسِ ࣖ',
        transliteration: 'Minal-jinnati wan-nās(i).',
        translation: 'dari (golongan) jin dan manusia.”',
      ),
    ],
    sourceLabel: 'Terjemah Qur’an Kemenag · 2019',
  );

  static final alBaqarahLastVerses = ReaderContent(
    id: 'al-baqarah-285-286',
    title: 'Al-Baqarah 285–286',
    context: 'Dua ayat terakhir Surah Al-Baqarah',
    sections: const [
      ReaderSection(
        heading: '2:285',
        arabic:
            'اٰمَنَ الرَّسُوْلُ بِمَآ اُنْزِلَ اِلَيْهِ مِنْ رَّبِّهٖ '
            'وَالْمُؤْمِنُوْنَۗ كُلٌّ اٰمَنَ بِاللّٰهِ وَمَلٰۤىِٕكَتِهٖ '
            'وَكُتُبِهٖ وَرُسُلِهٖۗ لَا نُفَرِّقُ بَيْنَ اَحَدٍ مِّنْ '
            'رُّسُلِهٖ ۗ وَقَالُوْا سَمِعْنَا وَاَطَعْنَا غُفْرَانَكَ '
            'رَبَّنَا وَاِلَيْكَ الْمَصِيْرُ',
        transliteration:
            'Āmanar-rasūlu bimā unzila ilaihi mir rabbihī wal-mu’minūn(a), '
            'kullun āmana billāhi wa malā’ikatihī wa kutubihī wa rusulih(ī), '
            'lā nufarriqu baina aḥadim mir rusulih(ī), wa qālū sami‘nā wa '
            'aṭa‘nā, gufrānaka rabbanā wa ilaikal-maṣīr(u).',
        translation:
            'Rasul (Muhammad) beriman pada apa (Al-Qur’an) yang diturunkan '
            'kepadanya dari Tuhannya, demikian pula orang-orang mukmin. '
            'Masing-masing beriman kepada Allah, malaikat-malaikat-Nya, '
            'kitab-kitab-Nya, dan rasul-rasul-Nya. (Mereka berkata,) “Kami '
            'tidak membeda-bedakan seorang pun dari rasul-rasul-Nya.” Mereka '
            'juga berkata, “Kami dengar dan kami taat. Ampunilah kami, wahai '
            'Tuhan kami. Hanya kepada-Mu tempat (kami) kembali.”',
      ),
      ReaderSection(
        heading: '2:286',
        arabic:
            'لَا يُكَلِّفُ اللّٰهُ نَفْسًا اِلَّا وُسْعَهَا ۗ لَهَا مَا '
            'كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا '
            'تُؤَاخِذْنَآ اِنْ نَّسِيْنَآ اَوْ اَخْطَأْنَا ۚ رَبَّنَا '
            'وَلَا تَحْمِلْ عَلَيْنَآ اِصْرًا كَمَا حَمَلْتَهٗ عَلَى '
            'الَّذِيْنَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا '
            'لَا طَاقَةَ لَنَا بِهٖۚ وَاعْفُ عَنَّاۗ وَاغْفِرْ لَنَاۗ '
            'وَارْحَمْنَا ۗ اَنْتَ مَوْلٰىنَا فَانْصُرْنَا عَلَى الْقَوْمِ '
            'الْكٰفِرِيْنَ ࣖ',
        transliteration:
            'Lā yukallifullāhu nafsan illā wus‘ahā, lahā mā kasabat wa ‘alaihā '
            'maktasabat, rabbanā lā tu’ākhiżnā in nasīnā au akhṭa’nā, rabbanā '
            'wa lā taḥmil ‘alainā iṣran kamā ḥamaltahū ‘alal-lażīna min '
            'qablinā, rabbanā wa lā tuḥammilnā mā lā ṭāqata lanā bih(ī), '
            'wa‘fu ‘annā, wagfir lanā, warḥamnā, anta maulānā fanṣurnā ‘alal '
            'qaumil-kāfirīn(a).',
        translation:
            'Allah tidak membebani seseorang, kecuali menurut kesanggupannya. '
            'Baginya ada sesuatu (pahala) dari (kebajikan) yang diusahakannya '
            'dan terhadapnya ada (pula) sesuatu (siksa) atas (kejahatan) yang '
            'diperbuatnya. (Mereka berdoa,) “Wahai Tuhan kami, janganlah Engkau '
            'hukum kami jika kami lupa atau kami salah. Wahai Tuhan kami, '
            'janganlah Engkau bebani kami dengan beban yang berat sebagaimana '
            'Engkau bebankan kepada orang-orang sebelum kami. Wahai Tuhan kami, '
            'janganlah Engkau pikulkan kepada kami apa yang tidak sanggup kami '
            'memikulnya. Maafkanlah kami, ampunilah kami, dan rahmatilah kami. '
            'Engkaulah pelindung kami. Maka, tolonglah kami dalam menghadapi '
            'kaum kafir.”',
      ),
    ],
    sourceLabel: 'Terjemah Qur’an Kemenag · 2019',
  );

  static const _basmala = ReaderSection(
    heading: 'Pembuka',
    arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
    transliteration: 'Bismillāhir-raḥmānir-raḥīm(i).',
    translation: 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
  );

  static ReaderContent? byRoute(String routineId, String contentId) {
    if (routineId == 'sholat-malam' && contentId == bedtimeDua.id) {
      return bedtimeDua;
    }
    if (routineId != 'penutup-hari') return null;
    return switch (contentId) {
      'doa-sebelum-tidur' => bedtimeDua,
      'ayat-kursi' => ayatKursi,
      'al-ikhlas' => alIkhlas,
      'al-falaq' => alFalaq,
      'an-nas' => anNas,
      'al-baqarah-285-286' => alBaqarahLastVerses,
      _ => null,
    };
  }
}
