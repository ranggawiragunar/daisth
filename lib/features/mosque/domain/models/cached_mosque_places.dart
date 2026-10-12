import 'mosque_place.dart';

class CachedMosquePlaces {
  CachedMosquePlaces({required List<MosquePlace> places, required this.isFresh})
    : places = List.unmodifiable(places);

  final List<MosquePlace> places;
  final bool isFresh;
}
