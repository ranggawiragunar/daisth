enum RoutinePriority {
  high('high'),
  medium('medium'),
  low('low');

  const RoutinePriority(this.storageValue);
  final String storageValue;

  static RoutinePriority? fromStorage(String value) => switch (value) {
    'high' => RoutinePriority.high,
    'medium' => RoutinePriority.medium,
    'low' => RoutinePriority.low,
    _ => null,
  };
}
