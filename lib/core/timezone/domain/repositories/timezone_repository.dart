import '../models/device_timezone.dart';

abstract interface class TimezoneRepository {
  Future<DeviceTimezone> initialize();

  Future<DeviceTimezone> getDeviceTimezone();
}
