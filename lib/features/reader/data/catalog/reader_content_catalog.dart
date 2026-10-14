import '../../domain/models/reader_content.dart';
import '../../domain/models/reader_section.dart';

/// Verified local Reader text used by the built-in bedtime routine.
/// Qur'an Latin transliterations follow the per-verse Qur'an Kemenag pages;
/// Indonesian translations use the 2019 translation edition.
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

  static final taubatAfterPrayer = ReaderContent(
    id: 'taubat-after-prayer',
    title: 'Bacaan setelah Sholat Taubat',
    titleEn: 'After Taubat Prayer',
    context: 'Istighfar dan doa',
    contextEn: 'Seeking forgiveness and supplication',
    sections: const [
      ReaderSection(
        heading: 'Istighfar',
        headingEn: 'Istighfar',
        arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
        transliteration: 'Astaghfirullāhal-‘aẓīma wa atūbu ilaih.',
        translation:
            'Aku memohon ampun kepada Allah Yang Maha Agung dan aku bertobat kepada-Nya.',
        translationEn:
            'I seek forgiveness from Allah, the Magnificent, and I repent to Him.',
        showFieldLabels: true,
      ),
      ReaderSection(
        heading: 'Sayyidul Istighfar',
        headingEn: 'Sayyidul Istighfar',
        arabic:
            'اللَّهُمَّ أَنْتَ رَبِّي، لَا إِلَهَ إِلَّا أَنْتَ، '
            'خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ '
            'مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، '
            'أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي، '
            'فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        transliteration:
            'Allāhumma anta rabbī, lā ilāha illā anta,\n'
            'khalaqtanī wa anā ‘abduka,\n'
            'wa anā ‘alā ‘ahdika wa wa‘dika mastatha‘tu.\n'
            'A‘ūdzu bika min syarri mā shana‘tu.\n'
            'Abū’u laka bini‘matika ‘alayya,\n'
            'wa abū’u laka bidzanbī,\n'
            'faghfir lī,\n'
            'fa innahu lā yaghfirudz-dzunūba illā anta.',
        translation:
            'Ya Allah, Engkau adalah Tuhanku.\n'
            'Tidak ada sesembahan yang berhak disembah selain Engkau.\n'
            'Engkau telah menciptakanku dan aku adalah hamba-Mu.\n'
            'Aku berpegang pada perjanjian dan janji-Mu semampuku.\n'
            'Aku berlindung kepada-Mu dari keburukan yang telah kuperbuat.\n'
            'Aku mengakui nikmat-Mu kepadaku dan aku mengakui dosaku.\n'
            'Maka ampunilah aku, karena tidak ada yang mengampuni dosa selain Engkau.',
        translationEn:
            'O Allah, You are my Lord.\n'
            'There is none worthy of worship except You.\n'
            'You created me and I am Your servant.\n'
            'I remain faithful to Your covenant and promise as much as I am able.\n'
            'I seek refuge in You from the evil of what I have done.\n'
            'I acknowledge Your blessings upon me, and I acknowledge my sins.\n'
            'So forgive me, for no one forgives sins except You.',
        sourceLabel: 'Sahih al-Bukhari 6306',
        sourceLabelEn: 'Sahih al-Bukhari 6306',
        showFieldLabels: true,
      ),
    ],
  );

  static final hajatAfterPrayer = ReaderContent(
    id: 'hajat-after-prayer',
    title: 'Bacaan setelah Sholat Hajat',
    titleEn: 'After Hajat Prayer',
    context: 'Pujian, sholawat, dan doa',
    contextEn: 'Praise, sholawat, and supplication',
    sections: const [
      ReaderSection(
        heading: 'Pujian & Sholawat',
        headingEn: 'Praise & Sholawat',
        arabic:
            'سُبْحَانَ الَّذِي لَبِسَ الْعِزَّ وَقَالَ بِهِ، '
            'سُبْحَانَ الَّذِي تَعَطَّفَ بِالْمَجْدِ وَتَكَرَّمَ بِهِ، '
            'سُبْحَانَ ذِي الْعِزِّ وَالْكَرَمِ، سُبْحَانَ ذِي الطَّوْلِ، '
            'أَسْأَلُكَ بِمَعَاقِدِ الْعِزِّ مِنْ عَرْشِكَ، '
            'وَمُنْتَهَى الرَّحْمَةِ مِنْ كِتَابِكَ، وَبِاسْمِكَ الْأَعْظَمِ، '
            'وَجَدِّكَ الْأَعْلَى، وَكَلِمَاتِكَ التَّامَّاتِ الْعَامَّاتِ '
            'الَّتِي لَا يُجَاوِزُهُنَّ بَرٌّ وَلَا فَاجِرٌ، '
            'أَنْ تُصَلِّيَ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
        transliteration:
            'Subḥānalladzī labisal-‘izza wa qāla bih.\n'
            'Subḥānalladzī ta‘aththafa bil-majdi wa takarrama bih.\n'
            'Subḥāna dzil-‘izzi wal-karam.\n'
            'Subḥāna dzith-thaul.\n'
            'As’aluka bima‘āqidil-‘izzi min ‘arsyik,\n'
            'wa muntahar-raḥmati min kitābik,\n'
            'wa bismikal-a‘ẓam,\n'
            'wa jaddikal-a‘lā,\n'
            'wa kalimātikat-tāmmātil-‘āmmātil-latī\n'
            'lā yujāwizuhunna barrun wa lā fājir,\n'
            'an tushalliya ‘alā Muḥammadin\n'
            'wa ‘alā āli Muḥammad.',
        translation:
            'Maha Suci Dia yang mengenakan kemuliaan dan berkuasa dengannya.\n'
            'Maha Suci Dia yang berselimut keagungan dan memuliakan diri dengannya.\n'
            'Maha Suci Pemilik kemuliaan dan kemurahan.\n'
            'Maha Suci Pemilik karunia yang luas.\n'
            'Aku memohon kepada-Mu dengan ikatan-ikatan kemuliaan dari ‘Arsy-Mu,\n'
            'puncak rahmat dari kitab-Mu,\n'
            'dengan nama-Mu Yang Maha Agung,\n'
            'keagungan-Mu Yang Mahatinggi,\n'
            'dan kalimat-kalimat-Mu yang sempurna dan menyeluruh\n'
            'yang tidak dapat dilampaui oleh orang baik maupun orang durhaka,\n'
            'agar Engkau melimpahkan sholawat kepada Muhammad\n'
            'dan keluarga Muhammad.',
        translationEn:
            'Glory be to the One clothed in might and sovereign through it.\n'
            'Glory be to the One adorned with majesty and honored through it.\n'
            'Glory be to the Possessor of might and generosity.\n'
            'Glory be to the Possessor of abundant bounty.\n'
            'I ask You by the bonds of might from Your Throne,\n'
            'by the utmost mercy in Your Book,\n'
            'by Your Greatest Name,\n'
            'by Your highest majesty,\n'
            'and by Your perfect and all-encompassing words\n'
            'which neither the righteous nor the wicked can surpass,\n'
            'to bestow blessings upon Muhammad\n'
            'and the family of Muhammad.',
        showFieldLabels: true,
      ),
      ReaderSection(
        heading: 'Doa Hajat',
        headingEn: 'Dua for Hajat',
        arabic:
            'لَا إِلَهَ إِلَّا اللَّهُ الْحَلِيمُ الْكَرِيمُ، '
            'سُبْحَانَ اللَّهِ رَبِّ الْعَرْشِ الْعَظِيمِ، '
            'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ، '
            'أَسْأَلُكَ مُوجِبَاتِ رَحْمَتِكَ، وَعَزَائِمَ مَغْفِرَتِكَ، '
            'وَالْغَنِيمَةَ مِنْ كُلِّ بِرٍّ، وَالسَّلَامَةَ مِنْ كُلِّ إِثْمٍ، '
            'لَا تَدَعْ لِي ذَنْبًا إِلَّا غَفَرْتَهُ، '
            'وَلَا هَمًّا إِلَّا فَرَّجْتَهُ، '
            'وَلَا حَاجَةً هِيَ لَكَ رِضًا إِلَّا قَضَيْتَهَا، '
            'يَا أَرْحَمَ الرَّاحِمِينَ',
        transliteration:
            'Lā ilāha illallāhul-ḥalīmul-karīm.\n'
            'Subḥānallāhi rabbil-‘arsyil-‘aẓīm.\n'
            'Al-ḥamdu lillāhi rabbil-‘ālamīn.\n'
            'As’aluka mūjibāti raḥmatik,\n'
            'wa ‘azā’ima maghfiratik,\n'
            'wal-ghanīmata min kulli birr,\n'
            'was-salāmata min kulli itsm.\n'
            'Lā tada‘ lī dzanban illā ghafartah,\n'
            'wa lā hamman illā farrajtah,\n'
            'wa lā ḥājatan hiya laka riḍan illā qaḍaitahā,\n'
            'yā arḥamar-rāḥimīn.',
        translation:
            'Tidak ada sesembahan yang berhak disembah selain Allah, '
            'Yang Maha Penyantun lagi Maha Mulia.\n'
            'Maha Suci Allah, Tuhan ‘Arsy yang agung.\n'
            'Segala puji bagi Allah, Tuhan seluruh alam.\n\n'
            'Aku memohon kepada-Mu segala hal yang mendatangkan rahmat-Mu,\n'
            'segala sebab yang membawa ampunan-Mu,\n'
            'keuntungan dari setiap kebaikan,\n'
            'dan keselamatan dari setiap dosa.\n\n'
            'Jangan Engkau biarkan satu dosa pun bagiku kecuali Engkau mengampuninya,\n'
            'satu kesusahan pun kecuali Engkau melapangkannya,\n'
            'dan satu kebutuhan yang Engkau ridhai kecuali Engkau memenuhinya,\n'
            'wahai Yang Maha Pengasih di antara para pengasih.',
        translationEn:
            'There is none worthy of worship except Allah, the Forbearing, the Generous.\n'
            'Glory be to Allah, Lord of the Magnificent Throne.\n'
            'All praise belongs to Allah, Lord of all worlds.\n\n'
            'I ask You for everything that brings about Your mercy,\n'
            'for the means that lead to Your forgiveness,\n'
            'for the gain of every good deed,\n'
            'and for safety from every sin.\n\n'
            'Leave no sin of mine except that You forgive it,\n'
            'no worry except that You relieve it,\n'
            'and no need that pleases You except that You fulfill it,\n'
            'O Most Merciful of those who show mercy.',
        sourceLabel: "Jami' at-Tirmidhi 479",
        sourceLabelEn: "Jami' at-Tirmidhi 479",
        note: 'Sanad riwayat ini memiliki catatan kelemahan.',
        noteEn: 'The chain of this narration has noted weakness.',
        showFieldLabels: true,
      ),
    ],
  );

  static const _basmala = ReaderSection(
    heading: 'Pembuka',
    arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
    transliteration: 'Bismillāhir-raḥmānir-raḥīm(i).',
    translation: 'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.',
  );

  static ReaderContent? byRoute(String routineId, String contentId) {
    if (routineId == 'sholat-malam') {
      return switch (contentId) {
        'taubat-after-prayer' => taubatAfterPrayer,
        'hajat-after-prayer' => hajatAfterPrayer,
        _ => null,
      };
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
