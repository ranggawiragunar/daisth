enum MosqueSearchFailureType { serviceBusy, unavailable }

class MosqueSearchFailure implements Exception {
  const MosqueSearchFailure(this.type);

  final MosqueSearchFailureType type;
}

class LocationUnavailableFailure implements Exception {
  const LocationUnavailableFailure();
}
