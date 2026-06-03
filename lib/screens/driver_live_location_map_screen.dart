import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLiveLocationMapScreen extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;

  const DriverLiveLocationMapScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  ConsumerState<DriverLiveLocationMapScreen> createState() =>
      _DriverLiveLocationMapScreenState();
}

class _DriverLiveLocationMapScreenState
    extends ConsumerState<DriverLiveLocationMapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _locationSubscription;

  LatLng? _driverLocation;
  bool _isOnline = false;
  DateTime? _lastUpdate;
  double? _speed;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _startListeningToLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startListeningToLocation() {
    _locationSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.driverId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final isOnline = data['isOnline'] ?? false;
      final GeoPoint? location = data['currentLocation'];
      final Timestamp? lastUpdate = data['lastLocationUpdate'];
      final double? speed = data['speed']?.toDouble();

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _speed = speed;

          if (lastUpdate != null) {
            _lastUpdate = lastUpdate.toDate();
          }

          if (location != null) {
            _driverLocation = LatLng(location.latitude, location.longitude);
            _updateMarker();


            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_driverLocation!),
            );
          } else {
            _driverLocation = null;
            _markers.clear();
          }
        });
      }
    });
  }

  void _updateMarker() {
    if (_driverLocation == null) return;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId(widget.driverId),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: widget.driverName,
          snippet: _isOnline ? 'Online' : 'Offline',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _driverLocation != null
              ? GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverLocation!,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Driver location not available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),


          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),


          if (_driverLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildStatusCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
            child: Text(
              widget.driverName.isNotEmpty
                  ? widget.driverName[0].toUpperCase()
                  : 'D',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isOnline ? Colors.green[700] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isOnline
                  ? Colors.green[50]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.my_location,
              color: _isOnline ? Colors.green[700] : Colors.grey,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                icon: Icons.speed,
                label: 'Speed',
                value: _speed != null
                    ? '${_speed!.toStringAsFixed(0)} km/h'
                    : '0 km/h',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildStatusItem(
                icon: Icons.update,
                label: 'Last Update',
                value: _lastUpdate != null
                    ? _getTimeAgo(_lastUpdate!)
                    : 'Never',
              ),
            ],
          ),
          if (!_isOnline) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver is offline. Location will update when they go online.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}