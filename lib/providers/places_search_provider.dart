import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/legacy.dart';

// Search result model
class PlaceSearchResult {
  final String name;
  final String address;
  final LatLng location;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.location,
  });
}

// Search provider
final placeSearchProvider = StateNotifierProvider<PlaceSearchNotifier, AsyncValue<PlaceSearchResult?>>((ref) {
  return PlaceSearchNotifier();
});

class PlaceSearchNotifier extends StateNotifier<AsyncValue<PlaceSearchResult?>> {
  PlaceSearchNotifier() : super(const AsyncValue.data(null));

  // Search for place by name
  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Use geocoding to find location
      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        state = AsyncValue.error('Location not found', StackTrace.current);
        return;
      }

      final location = locations.first;

      // Get place details (reverse geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      final placemark = placemarks.first;

      final result = PlaceSearchResult(
        name: query,
        address: '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}',
        location: LatLng(location.latitude, location.longitude),
      );

      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error('Failed to find location: ${e.toString()}', StackTrace.current);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Selected search result
final selectedPlaceProvider = StateProvider<PlaceSearchResult?>((ref) => null);