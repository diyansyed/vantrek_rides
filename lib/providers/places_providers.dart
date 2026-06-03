import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/legacy.dart';
final placesServiceProvider = Provider((ref) => GooglePlacesService());

final placesSearchResultsProvider = StateProvider<List<PlaceResult>>((ref) => []);

final selectedPlaceProvider = StateProvider<PlaceResult?>((ref) => null);

final placesLoadingProvider = StateProvider<bool>((ref) => false);

final placesErrorProvider = StateProvider<String?>((ref) => null);

final placesSearchQueryProvider = StateProvider<String>((ref) => '');

final autocompleteSuggestionsProvider = StateProvider<List<AutocompleteResult>>((ref) => []);

class PlacesSearchController extends StateNotifier<AsyncValue<List<PlaceResult>>> {
  final GooglePlacesService _placesService;

  PlacesSearchController(this._placesService) : super(const AsyncValue.data([]));

  Future<void> searchInstitutions(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final results = await _placesService.searchInstitutions(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchNearby() async {
    state = const AsyncValue.loading();

    try {

      final results = await _placesService.searchNearby(
        const LatLng(33.6844, 73.0479),
        radius: 50000,
      );
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final placesSearchControllerProvider =
StateNotifierProvider<PlacesSearchController, AsyncValue<List<PlaceResult>>>((ref) {
  final placesService = ref.watch(placesServiceProvider);
  return PlacesSearchController(placesService);
});

class AutocompleteController extends StateNotifier<AsyncValue<List<AutocompleteResult>>> {
  final GooglePlacesService _placesService;

  AutocompleteController(this._placesService) : super(const AsyncValue.data([]));

  Future<void> getSuggestions(String input) async {
    if (input.trim().length < 2) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final suggestions = await _placesService.getAutocompleteSuggestions(input);
      state = AsyncValue.data(suggestions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final autocompleteControllerProvider =
StateNotifierProvider<AutocompleteController, AsyncValue<List<AutocompleteResult>>>((ref) {
  final placesService = ref.watch(placesServiceProvider);
  return AutocompleteController(placesService);
});

