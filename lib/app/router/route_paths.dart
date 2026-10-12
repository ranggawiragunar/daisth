abstract final class RoutePaths {
  static const root = '/';
  static const today = '/today';
  static const history = '/history';
  static const routines = '/routines';
  static const settings = '/settings';
  static const routineDetailPattern = '/routines/:routineId';

  static String routineDetail(String routineId) => '/routines/$routineId';
}
