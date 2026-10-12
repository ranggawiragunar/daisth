import 'package:url_launcher/url_launcher.dart';

import '../../location/domain/models/geo_coordinate.dart';
import '../../../features/mosque/domain/models/mosque_place.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

class MapNavigationService {
  MapNavigationService({ExternalUriLauncher? launcher})
    : _launcher = launcher ?? _launchExternally;

  final ExternalUriLauncher _launcher;

  static Uri directionsUri(GeoCoordinate destination) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${destination.latitude},${destination.longitude}',
        'travelmode': 'walking',
        'dir_action': 'navigate',
      });

  static Uri get openStreetMapCopyrightUri =>
      Uri.https('www.openstreetmap.org', '/copyright');

  Future<bool> openWalkingDirections(MosquePlace place) =>
      _launcher(directionsUri(place.coordinate));

  Future<bool> openOpenStreetMapCopyright() =>
      _launcher(openStreetMapCopyrightUri);

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
