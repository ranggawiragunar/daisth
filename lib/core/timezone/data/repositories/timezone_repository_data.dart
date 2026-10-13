import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../domain/models/device_timezone.dart';
import '../../domain/repositories/timezone_repository.dart';
import '../services/timezone_flutter_service.dart';

class TimezoneRepositoryData implements TimezoneRepository {
  TimezoneRepositoryData({required this.service});

  final TimezoneFlutterService service;
  bool _databaseInitialized = false;

  @override
  Future<DeviceTimezone> initialize() async {
    if (!_databaseInitialized) {
      timezone_data.initializeTimeZones();
      _databaseInitialized = true;
    }
    return getDeviceTimezone();
  }

  @override
  Future<DeviceTimezone> getDeviceTimezone() async {
    if (!_databaseInitialized) {
      timezone_data.initializeTimeZones();
      _databaseInitialized = true;
    }
    final ianaName = await service.getLocalIanaName();
    timezone.setLocalLocation(timezone.getLocation(ianaName));
    return DeviceTimezone(ianaName: ianaName);
  }
}
