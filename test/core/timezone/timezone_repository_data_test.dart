import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/timezone/data/repositories/timezone_repository_data.dart';
import 'package:istiqam/core/timezone/data/services/timezone_flutter_service.dart';
import 'package:timezone/timezone.dart' as timezone;

void main() {
  test(
    'initializes timezone database and configures IANA local timezone',
    () async {
      final repository = TimezoneRepositoryData(
        service: _TimezoneService('Asia/Jakarta'),
      );

      final jakarta = await repository.initialize();
      expect(jakarta.ianaName, 'Asia/Jakarta');
      expect(timezone.local.name, 'Asia/Jakarta');

      final newYork = TimezoneRepositoryData(
        service: _TimezoneService('America/New_York'),
      );
      final timezoneName = await newYork.initialize();
      expect(timezoneName.ianaName, 'America/New_York');
      expect(timezone.local.name, 'America/New_York');
    },
  );
}

class _TimezoneService extends TimezoneFlutterService {
  _TimezoneService(this.ianaName);

  final String ianaName;

  @override
  Future<String> getLocalIanaName() async => ianaName;
}
