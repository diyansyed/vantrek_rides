import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class RideRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<String> sendRideRequest({
    required String driverId,
    required String driverName,
    required String institutionId,
    required String institutionName,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    String pickupLocation = '',
    String dropoffLocation = '',
    double? distanceKm,
    int? monthlyPrice,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final requestId = _uuid.v4();

    final requestData = {
      'id': requestId,
      'userId': user.uid,
      'userName': userData['name'] ?? user.displayName ?? 'User',
      'userPhone': userData['phoneNumber'] ?? '',
      'driverId': driverId,
      'driverName': driverName,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'pickupLocation': pickupAddress ?? pickupLocation,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'dropoffLocation': dropoffLocation,
      'distanceKm': distanceKm,
      'monthlyPrice': monthlyPrice,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    // Save to Firestore in multiple locations for easy querying
    final batch = _firestore.batch();

    // 1. Main ride requests collection
    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.set(requestRef, requestData);

    // 2. Driver's incoming requests subcollection
    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.set(driverRequestRef, requestData);

    // 3. User's sent requests subcollection
    final userRequestRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sentRequests')
        .doc(requestId);
    batch.set(userRequestRef, requestData);

    await batch.commit();

    return requestId;
  }

  // Get all pending requests for a driver
  Future<List<Map<String, dynamic>>> getDriverPendingRequests(
      String driverId) async {
    final snapshot = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Get pending requests count
  Future<int> getDriverPendingRequestsCount(String driverId) async {
    final snapshot = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  // Get all requests for a driver (pending, accepted, rejected)
  Stream<List<Map<String, dynamic>>> getDriverAllRequests(String driverId) {
    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Accept a ride request AND CREATE SUBSCRIPTION
  Future<void> acceptRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not logged in');

    final driverId = user.uid;

    print('═══════════════════════════════════════');
    print('ACCEPTING RIDE REQUEST');
    print('Request ID: $requestId');
    print('Driver ID: $driverId');

    // FIRST: Get the request data BEFORE updating
    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    final requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      throw Exception('Request not found');
    }

    final requestData = requestDoc.data()!;
    final userId = requestData['userId'];
    final userName = requestData['userName'] ?? 'User';
    final driverName = requestData['driverName'] ?? 'Driver';
    final userPhone = requestData['userPhone'] ?? '';

    print('User ID: $userId');
    print('User Name: $userName');
    print('Driver Name: $driverName');

    // Update status in batch
    final batch = _firestore.batch();

    // Update main collection
    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // Update driver's copy
    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.update(driverRequestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // Update user's copy
    if (userId != null) {
      final userRequestRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('sentRequests')
          .doc(requestId);
      batch.update(userRequestRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('✅ Request status updated to accepted');

    // CREATE SUBSCRIPTION - THIS IS THE KEY!
    print('Creating subscription...');

    final subscriptionId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));

    // GET MONTHLY PRICE FROM REQUEST DATA
    final monthlyPrice = requestData['monthlyPrice'] ?? 0;

    final subscriptionData = {
      'id': subscriptionId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'driverId': driverId,
      'driverName': driverName,
      'subscribedAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': 'active',
      'monthlyFee': monthlyPrice,
      'paymentMethod': 'manual',
      'lastPaymentDate': now.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final subBatch = _firestore.batch();

    // 1. Main subscriptions collection
    final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
    subBatch.set(subRef, subscriptionData);

    // 2. User's subscriptions subcollection
    final userSubRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('driverSubscriptions')
        .doc(subscriptionId);
    subBatch.set(userSubRef, subscriptionData);

    // 3. Driver's subscribers subcollection
    final driverSubRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .doc(subscriptionId);
    subBatch.set(driverSubRef, subscriptionData);

    // 4. Update driver's subscriber count
    final driverRef = _firestore.collection('drivers').doc(driverId);
    subBatch.set(driverRef, {
      'subscriberCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await subBatch.commit();

    print('✅ Subscription created! ID: $subscriptionId');
    print('═══════════════════════════════════════');
  }

  // Reject a ride request
  Future<void> rejectRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not logged in');

    final driverId = user.uid;
    final batch = _firestore.batch();

    // Update main collection
    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.update(requestRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // Update driver's copy
    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.update(driverRequestRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // Get userId from request to update user's copy
    final requestDoc = await requestRef.get();
    final userId = requestDoc.data()?['userId'];

    if (userId != null) {
      final userRequestRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('sentRequests')
          .doc(requestId);
      batch.update(userRequestRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Get user's sent requests
  Stream<List<Map<String, dynamic>>> getUserSentRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sentRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Delete a ride request
  Future<void> deleteRideRequest(String requestId, String userId) async {
    final batch = _firestore.batch();

    // Delete from main collection
    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.delete(requestRef);

    // Get the request data to find driverId
    final requestDoc = await requestRef.get();
    final driverId = requestDoc.data()?['driverId'];

    // Delete from driver's subcollection
    if (driverId != null) {
      final driverRequestRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('incomingRequests')
          .doc(requestId);
      batch.delete(driverRequestRef);
    }

    // Delete from user's subcollection
    final userRequestRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('sentRequests')
        .doc(requestId);
    batch.delete(userRequestRef);

    await batch.commit();
  }
}