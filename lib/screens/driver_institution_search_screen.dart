import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/google_places_service.dart';
import '../services/institution_service.dart';
import '../providers/places_providers.dart';
import '../widgets/route_input_dialog.dart';
import '../widgets/pickup_times_dialog.dart';

class DriverInstitutionSearchScreen extends ConsumerStatefulWidget {
  const DriverInstitutionSearchScreen({super.key});

  @override
  ConsumerState<DriverInstitutionSearchScreen> createState() =>
      _DriverInstitutionSearchScreenState();
}

class _DriverInstitutionSearchScreenState
    extends ConsumerState<DriverInstitutionSearchScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  bool _showSuggestions = false;
  List<String> _selectedRoute = [];
  List<String> _pickupTimes = [];
  List<String> _dropoffTimes = [];
  List<dynamic> _searchResults = []; // NEW: Store results locally
  bool _isSearching = false; // NEW: Loading state

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad
    zoom: 12,
  );

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search universities...',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) async {
                            if (value.length < 2) {
                              setState(() {
                                _showSuggestions = false;
                                _searchResults = [];
                              });
                              return;
                            }

                            setState(() {
                              _showSuggestions = true;
                              _isSearching = true;
                            });
                            String searchQuery = value;
                            if (!value.toLowerCase().contains('university') &&
                                !value.toLowerCase().contains('college') &&
                                !value.toLowerCase().contains('institute')) {
                              searchQuery = '$value university';
                            }

                            print('🔍 Searching for: $searchQuery, Islamabad');

                            try {
                              final placesService = ref.read(placesServiceProvider);
                              final results = await placesService.getAutocompleteSuggestions(
                                  '$searchQuery, Islamabad'
                              );

                              print('✅ Results found: ${results?.length ?? 0}');

                              if (mounted) {
                                setState(() {
                                  _searchResults = results ?? [];
                                  _isSearching = false;
                                });
                              }
                            } catch (e) {
                              print('❌ Error searching: $e');
                              if (mounted) {
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _showSuggestions = false;
                            });
                          },
                        ),
                      const Icon(Icons.search, color: Colors.grey),
                    ],
                  ),
                ),

                // Autocomplete Suggestions
                if (_showSuggestions && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
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
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.school,
                            color: Color(0xFF2196F3),
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
                          onTap: () async {
                            _searchController.text = suggestion.mainText;
                            setState(() {
                              _showSuggestions = false;
                            });
                            FocusScope.of(context).unfocus();

                            final placesService =
                            ref.read(placesServiceProvider);
                            final details = await placesService
                                .getPlaceDetails(suggestion.placeId);

                            if (details != null) {
                              _showInstitutionConfirmation(
                                details.name,
                                details.location,
                                suggestion.placeId,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),

                if (_showSuggestions && _isSearching && _searchResults.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
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
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Searching...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInstitutionConfirmation(
      String institutionName,
      LatLng location,
      String placeId,
      ) async {
    // First, ask for route
    final route = await showDialog<List<String>>(
      context: context,
      builder: (context) => RouteInputDialog(
        initialRoute: _selectedRoute,
      ),
    );

    if (route == null || route.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route is required (minimum 2 stops)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedRoute = route;
    });

    // Then, ask for pickup times
    final times = await showDialog<Map<String, List<String>>>(
      context: context,
      builder: (context) => PickupTimesDialog(
        initialPickupTimes: _pickupTimes,
        initialDropoffTimes: _dropoffTimes,
      ),
    );

    if (times == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup times are required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _pickupTimes = times['pickupTimes']!;
      _dropoffTimes = times['dropoffTimes']!;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF2196F3)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Register at Institution'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                institutionName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Your Route',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      route.join(' → '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Pickup Times
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Pickup Times',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pickupTimes.map((t) => _formatTimeDisplay(t)).join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.nightlight, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Dropoff Times',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dropoffTimes.map((t) => _formatTimeDisplay(t)).join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Do you want to register at this institution?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _registerAtInstitution(institutionName, location, placeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Register',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Future<void> _registerAtInstitution(
      String institutionName,
      LatLng location,
      String placeId,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final institutionService = InstitutionService();

      final institutionId = placeId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      await institutionService.registerAtInstitution(
        institutionId: institutionId,
        institutionName: institutionName,
        institutionLatitude: location.latitude,
        institutionLongitude: location.longitude,
        placeId: placeId,
        route: _selectedRoute,
        pickupTimes: _pickupTimes,
        dropoffTimes: _dropoffTimes,
      );

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registered at $institutionName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimeDisplay(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minute AM';
    if (hour == 12) return '12:$minute PM';
    return '${hour - 12}:$minute PM';
  }
}