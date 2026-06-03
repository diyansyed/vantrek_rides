import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyCISadp98kbi4BbVa_MD_bqx5eS-KF6tNk';

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlaceResult>> searchInstitutions(
    String query, {
    LatLng? location,
  }) async {
    try {

      final locationStr = location != null
          ? '${location.latitude},${location.longitude}'
          : '33.6844,73.0479'; // Islamabad coordinates as default

      final url = Uri.parse(
        '$_baseUrl/textsearch/json?'
        'query=$query university college school islamabad'
        '&location=$locationStr'
        '&radius=50000' // 50km radius
        '&type=university|school'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = (data['results'] as List)
              .map((place) => PlaceResult.fromJson(place))
              .toList();
          return results;
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw 'Places API error: ${data['status']}';
        }
      } else {
        throw 'HTTP error: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Search failed: $e';
    }
  }

  Future<List<AutocompleteResult>> getAutocompleteSuggestions(
    String input,
  ) async {
    if (input.length < 2) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?'
        'input=$input'
        '&location=33.6844,73.0479' // Islamabad
        '&radius=50000'
        '&types=establishment'
        '&components=country:pk' // Pakistan only
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((prediction) => AutocompleteResult.fromJson(prediction))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Autocomplete error: $e');
      return [];
    }
  }

  Future<PlaceResult?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?'
        'place_id=$placeId'
        '&fields=place_id,name,formatted_address,geometry,types,rating,user_ratings_total'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceResult.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Place details error: $e');
      return null;
    }
  }

  Future<List<PlaceResult>> searchNearby(
    LatLng location, {
    int radius = 10000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?'
        'location=${location.latitude},${location.longitude}'
        '&radius=$radius'
        '&type=university|school'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((place) => PlaceResult.fromJson(place))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Nearby search error: $e');
      return [];
    }
  }
}

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final List<String> types;
  final double? rating;
  final int? userRatingsTotal;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    required this.types,
    this.rating,
    this.userRatingsTotal,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];

    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      location: LatLng(
        (location?['lat'] ?? 0.0).toDouble(),
        (location?['lng'] ?? 0.0).toDouble(),
      ),
      types: List<String>.from(json['types'] ?? []),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
    );
  }

  String get institutionType {
    if (types.contains('university')) return 'University';
    if (types.contains('school')) return 'School';
    if (types.contains('secondary_school')) return 'College';
    return 'Institution';
  }
}

class AutocompleteResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  AutocompleteResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];

    return AutocompleteResult(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting?['main_text'] ?? '',
      secondaryText: structuredFormatting?['secondary_text'] ?? '',
    );
  }
}
