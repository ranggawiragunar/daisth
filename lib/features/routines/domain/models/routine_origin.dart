enum RoutineOrigin {
  defaultRoutine('default'),
  custom('custom');

  const RoutineOrigin(this.storageValue);
  final String storageValue;

  static RoutineOrigin? fromStorage(String value) => switch (value) {
    'default' => RoutineOrigin.defaultRoutine,
    'custom' => RoutineOrigin.custom,
    _ => null,
  };
}
