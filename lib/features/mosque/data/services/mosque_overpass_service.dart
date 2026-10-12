import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../models/mosque_place_data.dart';

enum OverpassFailureReason { serviceBusy, unavailable }

class OverpassServiceException implements Exception {
  const OverpassServiceException(this.reason);

  final OverpassFailureReason reason;
}

class MosqueOverpassService {
  MosqueOverpassService({
    required this.client,
    this.requestTimeout = const Duration(seconds: 9),
  });

  static final Uri primaryEndpoint = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );
  static final Uri fallbackEndpoint = Uri.parse(
    'https://overpass.private.coffee/api/interpreter',
  );
  static final Uri endpoint = primaryEndpoint;
  static final List<Uri> endpoints = List.unmodifiable([
    primaryEndpoint,
    fallbackEndpoint,
  ]);
  final http.Client client;
  final Duration requestTimeout;

  Future<List<MosquePlaceData>> fetchPlaces({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async {
    final query = _buildQuery(origin, radiusMeters);
    _AttemptFailure? lastFailure;

    for (final endpoint in endpoints) {
      try {
        final response = await _send(endpoint, query);
        if (response.statusCode == 200) return _parse(response.body);
        final retryable =
            response.statusCode == 429 ||
            (response.statusCode >= 500 && response.statusCode <= 599);
        final failure = _AttemptFailure(
          retryable
              ? OverpassFailureReason.serviceBusy
              : OverpassFailureReason.unavailable,
          retryable: retryable,
        );
        throw failure;
      } on _AttemptFailure catch (failure) {
        lastFailure = failure;
        if (!failure.retryable) {
          throw OverpassServiceException(failure.reason);
        }
      }
    }

    throw OverpassServiceException(
      lastFailure?.reason ?? OverpassFailureReason.unavailable,
    );
  }

  Future<http.Response> _send(Uri endpoint, String query) async {
    try {
      return await client
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Istiqam/1.0.0',
            },
            body: {'data': query},
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const _AttemptFailure(
        OverpassFailureReason.unavailable,
        retryable: true,
      );
    } on http.ClientException {
      throw const _AttemptFailure(
        OverpassFailureReason.unavailable,
        retryable: true,
      );
    } on Exception {
      throw const _AttemptFailure(
        OverpassFailureReason.unavailable,
        retryable: true,
      );
    }
  }

  List<MosquePlaceData> _parse(String body) {
    late final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected an Overpass JSON object.');
      }
      payload = decoded;
    } on FormatException {
      throw const OverpassServiceException(OverpassFailureReason.unavailable);
    }

    final elements = payload['elements'];
    if (elements is! List) {
      throw const OverpassServiceException(OverpassFailureReason.unavailable);
    }

    final placesById = <String, MosquePlaceData>{};
    for (final element in elements) {
      if (element is! Map) continue;
      final type = element['type'];
      final rawId = element['id'];
      if (type is! String || rawId is! num) continue;
      final point = _coordinates(element, type);
      if (point == null) continue;
      final rawTags = element['tags'];
      final tags = <String, String>{};
      if (rawTags is Map) {
        for (final entry in rawTags.entries) {
          if (entry.key is String && entry.value is String) {
            tags[entry.key as String] = entry.value as String;
          }
        }
      }
      final providerId = '$type/${rawId.toInt()}';
      placesById.putIfAbsent(
        providerId,
        () => MosquePlaceData(
          providerId: providerId,
          elementType: type,
          latitude: point.$1,
          longitude: point.$2,
          tags: tags,
        ),
      );
    }
    return List.unmodifiable(placesById.values);
  }

  String _buildQuery(GeoCoordinate origin, int radiusMeters) =>
      '''
[out:json][timeout:12];
(
  nwr(around:$radiusMeters,${origin.latitude},${origin.longitude})
    ["amenity"="place_of_worship"]["religion"="muslim"];
  nwr(around:$radiusMeters,${origin.latitude},${origin.longitude})
    ["place_of_worship"="musalla"]["religion"="muslim"];
);
out center tags;
''';

  (double, double)? _coordinates(Map element, String type) {
    final Object? latitude;
    final Object? longitude;
    if (type == 'node') {
      latitude = element['lat'];
      longitude = element['lon'];
    } else {
      final center = element['center'];
      if (center is! Map) return null;
      latitude = center['lat'];
      longitude = center['lon'];
    }
    if (latitude is! num || longitude is! num) return null;
    if (!latitude.isFinite || !longitude.isFinite) return null;
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return (latitude.toDouble(), longitude.toDouble());
  }
}

class _AttemptFailure implements Exception {
  const _AttemptFailure(this.reason, {required this.retryable});

  final OverpassFailureReason reason;
  final bool retryable;
}
