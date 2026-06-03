import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/google_places_service.dart';
import '../providers/places_providers.dart';
import 'institution_drivers_list_screen.dart';

class SearchInstitutionScreen extends ConsumerStatefulWidget {
  const SearchInstitutionScreen({super.key});

  @override
  ConsumerState<SearchInstitutionScreen> createState() =>
      _SearchInstitutionScreenState();
}

class _SearchInstitutionScreenState
    extends ConsumerState<SearchInstitutionScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  bool _showSuggestions = false;

  LatLng? _pickupLocation;
  String _pickupAddress = 'Getting current location...';
  bool _isLoadingLocation = true;
  bool _useCurrentLocation = true;
  final TextEditingController _pickupSearchController = TextEditingController();
  bool _showPickupSuggestions = false;
  bool _isPickupFocused = false;
  List<AutocompleteResult> _pickupSuggestions = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pickupSearchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _pickupAddress = 'Detecting your location...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Location timeout');
          },
        );

        print('📍 Location detected: ${position.latitude}, ${position.longitude}');

        setState(() {
          _pickupLocation = LatLng(position.latitude, position.longitude);
          _useCurrentLocation = true;
        });

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _pickupLocation!,
              zoom: 16,
            ),
          ),
        );

        await _getAddressFromLatLng(_pickupLocation!);
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        _pickupLocation = const LatLng(33.6844, 73.0479);
        _pickupAddress = 'Could not detect location. Tap map to select.';
        _isLoadingLocation = false;
        _useCurrentLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get location. Please enable GPS.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _pickupAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _pickupAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lng: ${position.longitude.toStringAsFixed(4)}';
        _isLoadingLocation = false;
      });
    }
  }

  void _onMapTap(LatLng location) {
    if (!_useCurrentLocation) {
      setState(() {
        _pickupLocation = location;
      });
      _getAddressFromLatLng(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(placesSearchControllerProvider);
    final autocompleteSuggestions = ref.watch(autocompleteControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: {
              ..._markers,
              if (_pickupLocation != null)
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: _pickupLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    _useCurrentLocation
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: InfoWindow(
                    title: _useCurrentLocation
                        ? '📍 Current Location'
                        : '🏠 Pickup Location',
                    snippet: _pickupAddress,
                  ),
                ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (location) {
              setState(() {
                _showSuggestions = false;
              });
              FocusScope.of(context).unfocus();
              _onMapTap(location);
            },
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  _buildPickupLocationCard(),
                  const SizedBox(height: 8),
                  _buildSearchBar(autocompleteSuggestions),
                ],
              ),
            ),
          ),

          if (searchResults.hasValue &&
              searchResults.value!.isNotEmpty &&
              !_showSuggestions &&
              !_isPickupFocused &&
              _searchController.text.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSearchResultsCard(searchResults.value!),
            ),

          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToIslamabad,
              child: const Icon(Icons.my_location, color: Color(0xFF2196F3)),
            ),
          ),

          if (searchResults.isLoading)
            const Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Searching...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                _useCurrentLocation ? Icons.my_location : Icons.location_on,
                color: _useCurrentLocation ? Colors.green : const Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pickupSearchController,
                  decoration: InputDecoration(
                    hintText: _pickupAddress,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: _isLoadingLocation ? Colors.grey : Colors.black87,
                      fontSize: 14,
                      fontWeight: _isLoadingLocation ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _showPickupSuggestions = value.isNotEmpty;
                      _useCurrentLocation = false;
                    });
                    if (value.isNotEmpty) {
                      _getPickupSuggestions(value);
                    } else {
                      setState(() {
                        _pickupSuggestions = [];
                      });
                    }
                  },
                  onTap: () {
                    setState(() {
                      _useCurrentLocation = false;
                      _isPickupFocused = true;
                    });
                  },
                ),
              ),
              if (_pickupSearchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _pickupSearchController.clear();
                    setState(() {
                      _showPickupSuggestions = false;
                      _pickupSuggestions = [];
                      _isPickupFocused = false;
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.gps_fixed,
                  size: 22,
                  color: const Color(0xFF2196F3),
                ),
                onPressed: () {
                  _pickupSearchController.clear();
                  setState(() {
                    _useCurrentLocation = true;
                    _showPickupSuggestions = false;
                    _pickupSuggestions = [];
                    _isPickupFocused = false;
                  });
                  FocusScope.of(context).unfocus();
                  _getCurrentLocation();
                },
                tooltip: 'Use current location',
              ),
            ],
          ),

          if (_showPickupSuggestions && _pickupSuggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _pickupSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _pickupSuggestions[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                    title: Text(
                      suggestion.mainText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      suggestion.secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    dense: true,
                    onTap: () async {
                      _pickupSearchController.text = suggestion.mainText;
                      setState(() {
                        _showPickupSuggestions = false;
                        _useCurrentLocation = false;
                        _isPickupFocused = false;
                      });
                      FocusScope.of(context).unfocus();

                      final placesService = ref.read(placesServiceProvider);
                      final details = await placesService
                          .getPlaceDetails(suggestion.placeId);

                      if (details != null) {
                        setState(() {
                          _pickupLocation = details.location;
                          _pickupAddress = details.name;
                        });

                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: _pickupLocation!,
                              zoom: 16,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _getPickupSuggestions(String query) async {
    try {
      final placesService = ref.read(placesServiceProvider);
      final suggestions = await placesService.getAutocompleteSuggestions(
        '$query, Islamabad',
      );

      setState(() {
        _pickupSuggestions = suggestions;
      });
    } catch (e) {
      print('Error getting pickup suggestions: $e');
    }
  }

  Widget _buildSearchBar(AsyncValue<List<AutocompleteResult>> suggestions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search universities, colleges...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _showSuggestions = value.isNotEmpty;
                    });
                    ref
                        .read(autocompleteControllerProvider.notifier)
                        .getSuggestions(value);
                  },
                  onSubmitted: (value) {
                    _performSearch(value);
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showSuggestions = false;
                    });
                    ref.read(autocompleteControllerProvider.notifier).clear();
                    ref.read(placesSearchControllerProvider.notifier).clear();
                    _clearMarkers();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                onPressed: () {
                  _performSearch(_searchController.text);
                },
              ),
            ],
          ),

          if (_showSuggestions && suggestions.hasValue)
            suggestions.when(
              data: (suggestionsList) {
                if (suggestionsList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No suggestions found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestionsList.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestionsList[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.school,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                        title: Text(
                          suggestion.mainText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          suggestion.secondaryText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        dense: true,
                        onTap: () async {
                          _searchController.text = suggestion.mainText;
                          setState(() {
                            _showSuggestions = false;
                          });
                          FocusScope.of(context).unfocus();

                          final placesService = ref.read(placesServiceProvider);
                          final details = await placesService
                              .getPlaceDetails(suggestion.placeId);

                          if (details != null) {
                            _showPlaceOnMap(details);
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsCard(List<PlaceResult> results) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(
                  'Found ${results.length} institutions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _buildResultCard(results[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(PlaceResult place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(
            Icons.school,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              place.address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (place.rating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${place.rating} (${place.userRatingsTotal ?? 0} reviews)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (_pickupLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select pickup location first'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final institutionId = place.placeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstitutionDriversListScreen(
                institutionId: institutionId,
                institutionName: place.name,
                pickupLatitude: _pickupLocation!.latitude,
                pickupLongitude: _pickupLocation!.longitude,
                pickupAddress: _pickupAddress,
                institutionLatitude: place.location.latitude,
                institutionLongitude: place.location.longitude,
              ),
            ),
          );
        },
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();

    ref.read(placesSearchControllerProvider.notifier).searchInstitutions(query);
  }

  void _showPlaceOnMap(PlaceResult place) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(place.placeId),
          position: place.location,
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: place.location,
          zoom: 15,
        ),
      ),
    );

    ref.read(placesSearchControllerProvider.notifier).state =
        AsyncValue.data([place]);
  }

  void _loadNearbyInstitutions() {
    ref.read(placesSearchControllerProvider.notifier).searchNearby();
  }

  void _goToIslamabad() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  void _clearMarkers() {
    setState(() {
      _markers = {};
    });
  }
}