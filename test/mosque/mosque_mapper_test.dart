import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/features/mosque/data/mappers/mosque_mapper.dart';
import 'package:daisth/features/mosque/data/models/mosque_place_data.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place_type.dart';

void main() {
  const origin = GeoCoordinate(latitude: -6.2, longitude: 106.8);
  final mapper = MosqueMapper();

  test(
    'uses explicit place_of_worship tags to classify mosque and musalla',
    () {
      final mosque = mapper.map(
        _place('mosque', {'place_of_worship': 'mosque'}),
        origin,
      );
      final musalla = mapper.map(
        _place('musalla', {'place_of_worship': 'musalla'}),
        origin,
      );

      expect(mosque.type, MosquePlaceType.mosque);
      expect(musalla.type, MosquePlaceType.musalla);
    },
  );

  test(
    'place names never determine subtype when structured subtype is absent',
    () {
      final mushollaName = mapper.map(
        _place('musholla-name', {
          'amenity': 'place_of_worship',
          'religion': 'muslim',
          'name': 'Musholla Al Ikhlas',
        }),
        origin,
      );
      final masjidName = mapper.map(
        _place('masjid-name', {
          'amenity': 'place_of_worship',
          'religion': 'muslim',
          'name': 'Masjid Example',
        }),
        origin,
      );

      expect(mushollaName.type, MosquePlaceType.unknown);
      expect(masjidName.type, MosquePlaceType.unknown);
      expect(mushollaName.name, 'Musholla Al Ikhlas');
      expect(masjidName.name, 'Masjid Example');
    },
  );

  test(
    'missing display names use fallback labels after tag classification',
    () {
      final mosque = mapper.map(
        _place('mosque', {'place_of_worship': 'mosque'}),
        origin,
      );
      final musalla = mapper.map(
        _place('musalla', {'place_of_worship': 'musalla'}),
        origin,
      );
      final unknown = mapper.map(
        _place('unknown', {
          'amenity': 'place_of_worship',
          'religion': 'muslim',
        }),
        origin,
      );

      expect(mosque.name, 'Masjid');
      expect(musalla.name, 'Mushola');
      expect(unknown.type, MosquePlaceType.unknown);
      expect(unknown.name, 'Tempat Sholat');
    },
  );
}

MosquePlaceData _place(String id, Map<String, String> tags) => MosquePlaceData(
  providerId: 'node/$id',
  elementType: 'node',
  latitude: -6.201,
  longitude: 106.8,
  tags: tags,
);
