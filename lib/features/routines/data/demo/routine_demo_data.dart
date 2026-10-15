import '../../../../core/design_system/assets/daisth_assets.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_requirement.dart';
import '../../domain/models/routine_step.dart';

abstract final class RoutineDemoData {
  static final sholatMalam = Routine(
    id: 'sholat-malam',
    title: 'Sholat Malam',
    description: 'Lengkapi rangkaian sholat malam sebelum masuk waktu Subuh.',
    preferredTime: '03:00',
    contextLabel: 'Before Subuh',
    isOptional: true,
    illustrationAsset: DaisthAssets.routineProgress,
    steps: [
      RoutineStep(
        id: 'tahajud',
        title: 'Tahajud',
        subtitle: '4 rakaat',
        rakaatCount: 4,
      ),
      RoutineStep(
        id: 'taubat',
        title: 'Sholat Taubat',
        subtitle: '2 rakaat',
        rakaatCount: 2,
      ),
      RoutineStep(
        id: 'hajat',
        title: 'Sholat Hajat',
        subtitle: '2 rakaat',
        rakaatCount: 2,
      ),
      RoutineStep(
        id: 'witir',
        title: 'Witir',
        subtitle: '3 rakaat',
        rakaatCount: 3,
      ),
    ],
  );

  static final dhuha = Routine(
    id: 'dhuha',
    title: 'Sholat Dhuha',
    description: 'Targetkan 4 rakaat jika memungkinkan. Minimum 2 rakaat.',
    preferredTime: '07:00',
    contextLabel: 'Window open',
    isOptional: true,
    illustrationAsset: DaisthAssets.routineProgress,
    steps: [
      RoutineStep(
        id: 'dhuha-minimum',
        title: '2 rakaat',
        subtitle: 'Mulai dari yang ringan',
        badge: 'Minimum',
        rakaatCount: 2,
        guidanceTitle: 'Panduan Sholat Dhuha',
        guidanceType: 'Reading',
      ),
      RoutineStep(
        id: 'dhuha-extra',
        title: 'Tambahan 2 rakaat',
        subtitle: 'Lengkapi hingga 4 rakaat',
        requirement: RoutineRequirement.optional,
        badge: 'Optional',
        rakaatCount: 2,
      ),
    ],
  );

  static final zuhur = Routine(
    id: 'zuhur',
    title: 'Sholat Zuhur',
    description: 'Laksanakan sholat Zuhur.',
    preferredTime: '',
    contextLabel: '',
    isOptional: false,
    steps: [
      RoutineStep(
        id: 'zuhur',
        title: 'Sholat Zuhur',
        subtitle: '4 rakaat',
        rakaatCount: 4,
      ),
      RoutineStep(
        id: 'post-prayer-dhikr',
        title: 'Zikir setelah salat',
        subtitle: 'Bisa dilanjutkan setelah sholat',
        requirement: RoutineRequirement.optional,
        guidanceTitle: 'Zikir setelah salat',
        guidanceType: 'Guidance',
      ),
    ],
  );

  static final subuh = _mandatoryPrayer(
    id: 'subuh',
    title: 'Sholat Subuh',
    rakaaCount: 2,
    additionalSteps: [
      RoutineStep(
        id: 'qabliyah-subuh',
        title: 'Qabliyah Subuh',
        subtitle: '2 rakaat',
        requirement: RoutineRequirement.optional,
        badge: 'Sunnah',
        rakaatCount: 2,
      ),
    ],
  );

  static final asar = _mandatoryPrayer(
    id: 'asar',
    title: 'Sholat Asar',
    rakaaCount: 4,
  );

  static final maghrib = _mandatoryPrayer(
    id: 'maghrib',
    title: 'Sholat Maghrib',
    rakaaCount: 3,
  );

  static final isya = _mandatoryPrayer(
    id: 'isya',
    title: 'Sholat Isya',
    rakaaCount: 4,
  );

  static final penutupHari = Routine(
    id: 'penutup-hari',
    title: 'Penutup Hari',
    description:
        'Bacaan sebelum tidur. Selesaikan yang terasa sesuai malam ini.',
    preferredTime: '',
    contextLabel: 'Sebelum tidur',
    isOptional: true,
    steps: const [
      RoutineStep(
        id: 'wudu',
        title: 'Wudu',
        subtitle: 'Persiapan',
        requirement: RoutineRequirement.optional,
        badge: 'Opsional',
        sectionTitle: 'Persiapan',
      ),
      RoutineStep(
        id: 'ayat-kursi',
        title: 'Ayat Kursi',
        subtitle: 'Al-Baqarah · 2:255',
        sectionTitle: 'Bacaan',
        readerContentId: 'ayat-kursi',
      ),
      RoutineStep(
        id: 'al-ikhlas',
        title: 'Al-Ikhlas',
        subtitle: 'Surah 112',
        sectionTitle: 'Bacaan',
        readerContentId: 'al-ikhlas',
      ),
      RoutineStep(
        id: 'al-falaq',
        title: 'Al-Falaq',
        subtitle: 'Surah 113',
        sectionTitle: 'Bacaan',
        readerContentId: 'al-falaq',
      ),
      RoutineStep(
        id: 'an-nas',
        title: 'An-Nas',
        subtitle: 'Surah 114',
        sectionTitle: 'Bacaan',
        readerContentId: 'an-nas',
      ),
      RoutineStep(
        id: 'al-baqarah-285-286',
        title: 'Al-Baqarah 285–286',
        subtitle: 'Dua ayat terakhir',
        sectionTitle: 'Bacaan',
        readerContentId: 'al-baqarah-285-286',
      ),
      RoutineStep(
        id: 'doa-sebelum-tidur',
        title: 'Doa Sebelum Tidur',
        subtitle: 'Sahih al-Bukhari 6314',
        sectionTitle: 'Penutup',
        readerContentId: 'doa-sebelum-tidur',
      ),
    ],
  );

  static Routine _mandatoryPrayer({
    required String id,
    required String title,
    required int rakaaCount,
    List<RoutineStep> additionalSteps = const [],
  }) => Routine(
    id: id,
    title: title,
    description: 'Laksanakan ${title.toLowerCase()}.',
    preferredTime: '',
    contextLabel: '',
    isOptional: false,
    steps: [
      ...additionalSteps,
      RoutineStep(
        id: id,
        title: title,
        subtitle: '$rakaaCount rakaat',
        rakaatCount: rakaaCount,
      ),
      RoutineStep(
        id: 'post-prayer-dhikr',
        title: 'Zikir setelah salat',
        subtitle: 'Bisa dilanjutkan setelah sholat',
        requirement: RoutineRequirement.optional,
        guidanceTitle: 'Zikir setelah salat',
        guidanceType: 'Guidance',
      ),
    ],
  );

  static Routine? byId(String id) => switch (id) {
    'sholat-malam' => sholatMalam,
    'dhuha' => dhuha,
    'subuh' => subuh,
    'zuhur' => zuhur,
    'asar' => asar,
    'maghrib' => maghrib,
    'isya' => isya,
    'penutup-hari' => penutupHari,
    _ => null,
  };
}
