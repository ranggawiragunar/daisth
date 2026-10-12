import 'dart:math' as math;

import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/mosque_place_type.dart';
import '../models/mosque_place_data.dart';

class MosqueMapper {
  MosquePlace map(MosquePlaceData data, GeoCoordinate origin) {
    final type = _mapType(data.tags);
    final rawName = data.tags['name']?.trim();
    final name = rawName == null || rawName.isEmpty
        ? _fallbackName(type)
        : rawName;
    final address = _address(data.tags);
    final coordinate = GeoCoordinate(
      latitude: data.latitude,
      longitude: data.longitude,
    );
    return MosquePlace(
      id: data.providerId,
      name: name,
      coordinate: coordinate,
      distanceMeters: _distanceMeters(origin, coordinate),
      type: type,
      shortAddress: address,
    );
  }

  MosquePlaceType _mapType(Map<String, String> tags) {
    final placeOfWorship = tags['place_of_worship']?.trim().toLowerCase();
    return switch (placeOfWorship) {
      'musalla' => MosquePlaceType.musalla,
      'mosque' => MosquePlaceType.mosque,
      _ => MosquePlaceType.unknown,
    };
  }

  String _fallbackName(MosquePlaceType type) => switch (type) {
    MosquePlaceType.mosque => 'Masjid',
    MosquePlaceType.musalla => 'Mushola',
    MosquePlaceType.unknown => 'Tempat Sholat',
  };

  String? _address(Map<String, String> tags) {
    final street = tags['addr:street']?.trim();
    final houseNumber = tags['addr:housenumber']?.trim();
    final streetLine = [
      if (street != null && street.isNotEmpty) street,
      if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
    ].join(' ');
    final parts = <String>{
      if (streetLine.isNotEmpty) streetLine,
      if ((tags['addr:suburb']?.trim().isNotEmpty ?? false))
        tags['addr:suburb']!.trim(),
      if ((tags['addr:city']?.trim().isNotEmpty ?? false))
        tags['addr:city']!.trim(),
    };
    return parts.isEmpty ? null : parts.join(', ');
  }

  double _distanceMeters(GeoCoordinate origin, GeoCoordinate place) {
    const earthRadius = 6371000.0;
    final latitudeDifference = _radians(place.latitude - origin.latitude);
    final longitudeDifference = _radians(place.longitude - origin.longitude);
    final originLatitude = _radians(origin.latitude);
    final placeLatitude = _radians(place.latitude);
    final a =
        math.pow(math.sin(latitudeDifference / 2), 2) +
        math.cos(originLatitude) *
            math.cos(placeLatitude) *
            math.pow(math.sin(longitudeDifference / 2), 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
