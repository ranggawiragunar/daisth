import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/maps/services/map_navigation_service.dart';

void main() {
  test('builds encoded walking directions URL', () {
    final uri = MapNavigationService.directionsUri(
      const GeoCoordinate(latitude: -6.2088, longitude: 106.8456),
    );
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {
      'api': '1',
      'destination': '-6.2088,106.8456',
      'travelmode': 'walking',
      'dir_action': 'navigate',
    });
  });
}
