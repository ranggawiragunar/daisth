class MosquePlaceData {
  MosquePlaceData({
    required this.providerId,
    required this.elementType,
    required this.latitude,
    required this.longitude,
    required Map<String, String> tags,
  }) : tags = Map.unmodifiable(tags);

  final String providerId;
  final String elementType;
  final double latitude;
  final double longitude;
  final Map<String, String> tags;
}
