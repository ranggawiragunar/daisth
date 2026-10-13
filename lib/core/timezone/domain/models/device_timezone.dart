class DeviceTimezone {
  const DeviceTimezone({required this.ianaName});

  final String ianaName;

  @override
  bool operator ==(Object other) =>
      other is DeviceTimezone && other.ianaName == ianaName;

  @override
  int get hashCode => ianaName.hashCode;
}
