import 'package:flutter_timezone/flutter_timezone.dart';

class TimezoneFlutterService {
  Future<String> getLocalIanaName() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
  }
}
