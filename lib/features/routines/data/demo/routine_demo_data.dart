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
    illustrationAsset: 'assets/illustrations/routine_progress.png',
    steps: [
      RoutineStep(
        id: 'tahajud',
        title: 'Tahajud',
        subtitle: '4 rakaat',
        completed: true,
        rakaatCount: 4,
        guidanceTitle: 'Doa setelah Tahajud',
        guidanceType: 'Rich text',
      ),
      RoutineStep(
        id: 'taubat',
        title: 'Sholat Taubat',
        subtitle: '2 rakaat',
        completed: true,
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
        guidanceTitle: 'Panduan Witir',
        guidanceType: 'Reading',
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
    illustrationAsset: 'assets/illustrations/routine_progress.png',
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
    preferredTime: '11:47',
    contextLabel: 'Due now',
    isOptional: false,
    steps: [
      RoutineStep(
        id: 'zuhur',
        title: 'Sholat Zuhur',
        subtitle: '4 rakaat',
        rakaatCount: 4,
      ),
      RoutineStep(
        id: 'dhikr',
        title: 'Dzikir setelah sholat',
        subtitle: 'Bisa dilanjutkan setelah sholat',
        requirement: RoutineRequirement.optional,
        guidanceTitle: 'Dzikir setelah sholat',
        guidanceType: 'Guidance',
      ),
    ],
  );

  static Routine? byId(String id) => switch (id) {
    'sholat-malam' => sholatMalam,
    'dhuha' => dhuha,
    'zuhur' => zuhur,
    _ => null,
  };
}
