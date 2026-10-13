abstract final class RoutePaths {
  static const root = '/';
  static const today = '/today';
  static const history = '/history';
  static const routines = '/routines';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const account = '/settings/account';
  static const routineDetailPattern = '/routines/:routineId';
  static const historyDayPattern = '/history/:date';
  static const reflection = '/reflection';
  static const readerPathSegment = 'reader/:contentId';
  static const dhikrPathSegment = 'dhikr/:dhikrId';
  static const mosquesPathSegment = 'mosques';

  static String routineDetail(String routineId) => '/routines/$routineId';

  static String historyDay(String date) => '/history/$date';

  static String historyRoutine(String date, String routineId) =>
      '/history/$date/routines/$routineId';

  static String historyReflection(String date) => '/history/$date/reflection';

  static String reader(String routineId, String contentId) =>
      '/routines/$routineId/reader/$contentId';

  static String dhikr(String routineId, String dhikrId) =>
      '/routines/$routineId/dhikr/$dhikrId';

  static String mosques(String routineId) => '/routines/$routineId/mosques';
}
