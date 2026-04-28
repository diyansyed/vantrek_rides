import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a rating for a driver
  Future<void> rateDriver({
    required String driverId,
    required String driverName,
    required double rating,
    String? review,
    String? rideId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not logged in';

    // Get user name
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final userName = userDoc.data()?['name'] ?? 'User';

    // Create rating
    final ratingData = Rating(
      ratingId: '',
      userId: currentUser.uid,
      userName: userName,
      driverId: driverId,
      driverName: driverName,
      rating: rating,
      review: review,
      createdAt: DateTime.now(),
      rideId: rideId,
    );

    // Save to ratings collection
    await _firestore.collection('ratings').add(ratingData.toMap());

    // Update driver's average rating
    await _updateDriverRating(driverId);
  }

  // Update driver's average rating
  Future<void> _updateDriverRating(String driverId) async {
    try {
      // Get all ratings for this driver
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('driverId', isEqualTo: driverId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return;
      }

      // Calculate average
      double totalRating = 0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = Rating.fromMap(doc.data(), doc.id);
        totalRating += rating.rating;
        count++;
      }

      final averageRating = totalRating / count;

      // Update driver document
      await _firestore.collection('drivers').doc(driverId).update({
        'rating': averageRating,
        'totalRatings': count,
      });
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }

  // Check if user has already rated a driver
  Future<bool> hasUserRatedDriver(String driverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final snapshot = await _firestore
        .collection('ratings')
        .where('userId', isEqualTo: currentUser.uid)
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get user's rating for a specific driver
  Future<Rating?> getUserRatingForDriver(String driverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final snapshot = await _firestore
        .collection('ratings')
        .where('userId', isEqualTo: currentUser.uid)
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Rating.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  // Get all ratings for a driver (for display)
  Stream<List<Rating>> getDriverRatings(String driverId) {
    return _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Rating.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all ratings by a user
  Stream<List<Rating>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Rating.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update an existing rating
  Future<void> updateRating({
    required String ratingId,
    required double rating,
    String? review,
  }) async {
    final ratingDoc = await _firestore.collection('ratings').doc(ratingId).get();

    if (!ratingDoc.exists) throw 'Rating not found';

    await _firestore.collection('ratings').doc(ratingId).update({
      'rating': rating,
      'review': review,
    });

    // Update driver's average rating
    final ratingData = Rating.fromMap(ratingDoc.data()!, ratingId);
    await _updateDriverRating(ratingData.driverId);
  }

  // Delete a rating
  Future<void> deleteRating(String ratingId) async {
    final ratingDoc = await _firestore.collection('ratings').doc(ratingId).get();

    if (!ratingDoc.exists) throw 'Rating not found';

    final ratingData = Rating.fromMap(ratingDoc.data()!, ratingId);

    await _firestore.collection('ratings').doc(ratingId).delete();

    // Update driver's average rating
    await _updateDriverRating(ratingData.driverId);
  }

  // Get rating statistics for a driver
  Future<Map<String, dynamic>> getDriverRatingStats(String driverId) async {
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'fiveStars': 0,
        'fourStars': 0,
        'threeStars': 0,
        'twoStars': 0,
        'oneStar': 0,
      };
    }

    int fiveStars = 0, fourStars = 0, threeStars = 0, twoStars = 0, oneStar = 0;
    double totalRating = 0;

    for (var doc in ratingsSnapshot.docs) {
      final rating = Rating.fromMap(doc.data(), doc.id);
      totalRating += rating.rating;

      if (rating.rating >= 4.5) {
        fiveStars++;
      } else if (rating.rating >= 3.5) {
        fourStars++;
      } else if (rating.rating >= 2.5) {
        threeStars++;
      } else if (rating.rating >= 1.5) {
        twoStars++;
      } else {
        oneStar++;
      }
    }

    return {
      'averageRating': totalRating / ratingsSnapshot.docs.length,
      'totalRatings': ratingsSnapshot.docs.length,
      'fiveStars': fiveStars,
      'fourStars': fourStars,
      'threeStars': threeStars,
      'twoStars': twoStars,
      'oneStar': oneStar,
    };
  }
}