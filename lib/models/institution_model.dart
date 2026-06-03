import 'package:google_maps_flutter/google_maps_flutter.dart';

class Institution {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final InstitutionType type;
  final int availableDrivers;
  final String imageUrl;
  final String description;
  final List<String> amenities;

  Institution({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    this.availableDrivers = 0,
    this.imageUrl = '',
    this.description = '',
    this.amenities = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.name,
      'availableDrivers': availableDrivers,
      'imageUrl': imageUrl,
      'description': description,
      'amenities': amenities,
    };
  }

  factory Institution.fromMap(Map<String, dynamic> map) {
    return Institution(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      location: LatLng(
        (map['latitude'] ?? 0.0).toDouble(),
        (map['longitude'] ?? 0.0).toDouble(),
      ),
      type: InstitutionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => InstitutionType.university,
      ),
      availableDrivers: map['availableDrivers'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      amenities: List<String>.from(map['amenities'] ?? []),
    );
  }

  String get typeDisplay {
    switch (type) {
      case InstitutionType.university:
        return 'University';
      case InstitutionType.college:
        return 'College';
      case InstitutionType.school:
        return 'School';
      case InstitutionType.academy:
        return 'Academy';
    }
  }
}

enum InstitutionType {
  university,
  college,
  school,
  academy,
}