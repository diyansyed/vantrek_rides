import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String ratingId;
  final String userId;
  final String userName;
  final String driverId;
  final String driverName;
  final double rating; // 1-5 stars
  final String? review; // Optional text review
  final DateTime createdAt;
  final String? rideId; // Optional: link to specific ride

  Rating({
    required this.ratingId,
    required this.userId,
    required this.userName,
    required this.driverId,
    required this.driverName,
    required this.rating,
    this.review,
    required this.createdAt,
    this.rideId,
  });

  factory Rating.fromMap(Map<String, dynamic> map, String id) {
    return Rating(
      ratingId: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      review: map['review'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      rideId: map['rideId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'driverId': driverId,
      'driverName': driverName,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'rideId': rideId,
    };
  }

  Rating copyWith({
    String? ratingId,
    String? userId,
    String? userName,
    String? driverId,
    String? driverName,
    double? rating,
    String? review,
    DateTime? createdAt,
    String? rideId,
  }) {
    return Rating(
      ratingId: ratingId ?? this.ratingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      rideId: rideId ?? this.rideId,
    );
  }
}