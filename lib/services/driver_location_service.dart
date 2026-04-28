import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;

  /// Start sharing live location
  Future<void> startSharingLocation() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Check location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get initial position and update immediately
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocationInFirestore(position);
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) async {
        await _updateLocationInFirestore(position);
      },
      onError: (error) {
        print('Location stream error: $error');
      },
    );

    // Also update every 10 seconds even if not moving
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _updateLocationInFirestore(position);
      } catch (e) {
        print('Timer update error: $e');
      }
    });

    print('Started sharing location');
  }

  /// Stop sharing live location
  Future<void> stopSharingLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel subscriptions
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    _updateTimer?.cancel();
    _updateTimer = null;

    // Remove location from Firestore
    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentLocation': null,
        'lastLocationUpdate': null,
        'isOnline': false,
      });
      print('Stopped sharing location');
    } catch (e) {
      print('Error stopping location sharing: $e');
    }
  }

  /// Update location in Firestore
  Future<void> _updateLocationInFirestore(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isOnline': true,
        'speed': position.speed,
        'heading': position.heading,
      });

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get current location once (without streaming)
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Check if currently sharing location
  bool get isSharingLocation => _positionStreamSubscription != null;

  /// Clean up resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
  }
}