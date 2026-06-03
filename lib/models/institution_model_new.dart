import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class Institution {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String? placeId;

  Institution({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.placeId,
  });

  factory Institution.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Institution(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      location: LatLng(
        data['latitude'] ?? 0.0,
        data['longitude'] ?? 0.0,
      ),
      placeId: data['placeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'placeId': placeId,
    };
  }
}

class InstitutionDriver {
  final String driverId;
  final String name;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleNumber;
  final bool isOnline;
  final double rating;
  final int totalRides;
  final List<String> route;
  final List<String> pickupTimes;
  final List<String> dropoffTimes;

  InstitutionDriver({
    required this.driverId,
    required this.name,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    required this.rating,
    required this.totalRides,
    this.route = const [],
    this.pickupTimes = const [],
    this.dropoffTimes = const [],
  });

  factory InstitutionDriver.fromMap(Map<String, dynamic> data) {
    return InstitutionDriver(
      driverId: data['driverId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? 'Car',
      vehicleNumber: data['vehicleNumber'] ?? '',
      isOnline: data['isOnline'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      route: List<String>.from(data['route'] ?? []),
      pickupTimes: List<String>.from(data['pickupTimes'] ?? []),     // NEW
      dropoffTimes: List<String>.from(data['dropoffTimes'] ?? []),   // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'name': name,
      'phoneNumber': phoneNumber,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'isOnline': isOnline,
      'rating': rating,
      'totalRides': totalRides,
      'route': route,
      'pickupTimes': pickupTimes,
      'dropoffTimes': dropoffTimes,
    };
  }
}