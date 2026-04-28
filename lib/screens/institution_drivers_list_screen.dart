import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/institution_service.dart';
import '../services/ride_request_service.dart';
import '../models/institution_model_new.dart';

class InstitutionDriversListScreen extends ConsumerStatefulWidget {
  final String institutionId;
  final String institutionName;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double institutionLatitude;
  final double institutionLongitude;

  const InstitutionDriversListScreen({
    super.key,
    required this.institutionId,
    required this.institutionName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.institutionLatitude,
    required this.institutionLongitude,
  });

  @override
  ConsumerState<InstitutionDriversListScreen> createState() =>
      _InstitutionDriversListScreenState();
}

class _InstitutionDriversListScreenState
    extends ConsumerState<InstitutionDriversListScreen> {
  final InstitutionService _institutionService = InstitutionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<InstitutionDriver> _drivers = [];
  bool _isLoading = true;
  bool _showOnlineOnly = false;
  Set<String> _sentRequestDriverIds = {}; // Track drivers we've sent requests to
  Set<String> _subscribedDriverIds = {}; // Track drivers we're already subscribed to
  double _distanceKm = 0.0;
  int _monthlyPrice = 0;

  @override
  void initState() {
    super.initState();
    _calculateDistanceAndPrice();
    _loadDrivers();
    _loadSentRequests();
    _loadSubscriptions(); // NEW: Check existing subscriptions
  }

  void _calculateDistanceAndPrice() {
    _distanceKm = Geolocator.distanceBetween(
      widget.pickupLatitude,
      widget.pickupLongitude,
      widget.institutionLatitude,
      widget.institutionLongitude,
    ) / 1000;
    _monthlyPrice = (_distanceKm * 400).round();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final drivers = await _institutionService.getDriversAtInstitution(
        widget.institutionId,
      );
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading drivers: $e')),
        );
      }
    }
  }

  Future<void> _loadSentRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sentRequests')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _sentRequestDriverIds = snapshot.docs
            .map((doc) => doc.data()['driverId'] as String)
            .toSet();
      });
    } catch (e) {
      print('Error loading sent requests: $e');
    }
  }

  // NEW: Load existing subscriptions
  Future<void> _loadSubscriptions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('═══════════════════════════════════════');
      print('CHECKING EXISTING SUBSCRIPTIONS');
      print('User ID: ${user.uid}');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('driverSubscriptions')
          .where('status', isEqualTo: 'active')
          .get();

      final subscribedIds = snapshot.docs
          .map((doc) => doc.data()['driverId'] as String)
          .toSet();

      print('Already subscribed to ${subscribedIds.length} drivers');
      print('Driver IDs: $subscribedIds');
      print('═══════════════════════════════════════');

      setState(() {
        _subscribedDriverIds = subscribedIds;
      });
    } catch (e) {
      print('Error loading subscriptions: $e');
    }
  }

  List<InstitutionDriver> get _filteredDrivers {
    if (_showOnlineOnly) {
      return _drivers.where((d) => d.isOnline).toList();
    }
    return _drivers;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _filteredDrivers;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Drivers',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.institutionName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlineOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showOnlineOnly ? const Color(0xFF2196F3) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showOnlineOnly = !_showOnlineOnly;
              });
            },
            tooltip: 'Show online only',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await _loadDrivers();
          await _loadSentRequests();
          await _loadSubscriptions();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildPickupInfo(),
                  _buildPriceInfo(),
                  _buildStatsHeader(filteredDrivers),
                ],
              ),
            ),
            filteredDrivers.isEmpty
                ? SliverFillRemaining(
              child: _buildEmptyState(),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildDriverCard(filteredDrivers[index]);
                },
                childCount: filteredDrivers.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.pickupAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Monthly Cost',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_monthlyPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.route,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_distanceKm.toStringAsFixed(1)} km • Rs. 400/km',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<InstitutionDriver> drivers) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_taxi,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${drivers.length} ${drivers.length == 1 ? 'Driver' : 'Drivers'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_taxi_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _showOnlineOnly ? 'No Online Drivers' : 'No Drivers Yet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _showOnlineOnly
                  ? 'No drivers are currently online at this institution'
                  : 'No drivers have registered at this institution yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            if (_showOnlineOnly) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showOnlineOnly = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Show All Drivers'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(InstitutionDriver driver) {
    // Check if already subscribed or request sent
    final isSubscribed = _subscribedDriverIds.contains(driver.driverId);
    final hasRequestPending = _sentRequestDriverIds.contains(driver.driverId);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                  child: Text(
                    driver.name.isNotEmpty
                        ? driver.name[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                      fontSize: 24,
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
                        driver.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // NEW: Show subscription status
                      if (isSubscribed) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Already Subscribed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        driver.rating > 0
                            ? driver.rating.toStringAsFixed(1)
                            : 'New',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.directions_car, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_getVehicleTypeName(driver.vehicleType)} • ${driver.vehicleNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.route, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${driver.totalRides} ${driver.totalRides == 1 ? 'ride' : 'rides'} completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (driver.route.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.route, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route: ${driver.route.join(" → ")}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (driver.pickupTimes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wb_sunny, size: 18, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup: ${driver.pickupTimes.take(3).map((t) => _formatTimeDisplay(t)).join(", ")}${driver.pickupTimes.length > 3 ? "..." : ""}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (driver.dropoffTimes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.nightlight, size: 18, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dropoff: ${driver.dropoffTimes.take(3).map((t) => _formatTimeDisplay(t)).join(", ")}${driver.dropoffTimes.length > 3 ? "..." : ""}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callDriver(driver.phoneNumber),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(color: Color(0xFF2196F3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isSubscribed
                      ? ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Subscribed'),
                  )
                      : hasRequestPending
                      ? ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[600],
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Request Sent'),
                  )
                      : ElevatedButton.icon(
                    onPressed: () => _sendRideRequest(driver),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'Car';
      case 'van':
        return 'Van';
      case 'bike':
        return 'Bike';
      case 'rickshaw':
        return 'Rickshaw';
      case 'suv':
        return 'SUV';
      default:
        return type;
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

  void _callDriver(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    launchUrl(uri);
  }

  void _sendRideRequest(InstitutionDriver driver) async {
    // Double check subscription status
    if (_subscribedDriverIds.contains(driver.driverId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already subscribed to this driver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_sentRequestDriverIds.contains(driver.driverId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already sent a request to this driver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final rideRequestService = RideRequestService();
      await rideRequestService.sendRideRequest(
        driverId: driver.driverId,
        driverName: driver.name,
        institutionId: widget.institutionId,
        institutionName: widget.institutionName,
        pickupLatitude: widget.pickupLatitude,
        pickupLongitude: widget.pickupLongitude,
        pickupAddress: widget.pickupAddress,
        distanceKm: _distanceKm,
        monthlyPrice: _monthlyPrice,
      );

      setState(() {
        _sentRequestDriverIds.add(driver.driverId);
      });

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Request Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your request has been sent to ${driver.name}. You\'ll be notified when they respond.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}