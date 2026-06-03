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

    final batch = _firestore.batch();

    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.set(requestRef, requestData);

    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.set(driverRequestRef, requestData);

    final userRequestRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sentRequests')
        .doc(requestId);
    batch.set(userRequestRef, requestData);

    await batch.commit();

    return requestId;
  }

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

  Future<int> getDriverPendingRequestsCount(String driverId) async {
    final snapshot = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

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

  Future<void> acceptRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not logged in');

    final driverId = user.uid;

    print('═══════════════════════════════════════');
    print('ACCEPTING RIDE REQUEST');
    print('Request ID: $requestId');
    print('Driver ID: $driverId');
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

    final batch = _firestore.batch();

    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.update(driverRequestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

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

    print('Creating subscription...');

    final subscriptionId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));

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

    final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
    subBatch.set(subRef, subscriptionData);

    final userSubRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('driverSubscriptions')
        .doc(subscriptionId);
    subBatch.set(userSubRef, subscriptionData);

    final driverSubRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .doc(subscriptionId);
    subBatch.set(driverSubRef, subscriptionData);

    final driverRef = _firestore.collection('drivers').doc(driverId);
    subBatch.set(driverRef, {
      'subscriberCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await subBatch.commit();

    print('✅ Subscription created! ID: $subscriptionId');
    print('═══════════════════════════════════════');
  }

  Future<void> rejectRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Driver not logged in');

    final driverId = user.uid;
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.update(requestRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    final driverRequestRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('incomingRequests')
        .doc(requestId);
    batch.update(driverRequestRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

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

  Future<void> deleteRideRequest(String requestId, String userId) async {
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('rideRequests').doc(requestId);
    batch.delete(requestRef);

    final requestDoc = await requestRef.get();
    final driverId = requestDoc.data()?['driverId'];

    if (driverId != null) {
      final driverRequestRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('incomingRequests')
          .doc(requestId);
      batch.delete(driverRequestRef);
    }
    final userRequestRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('sentRequests')
        .doc(requestId);
    batch.delete(userRequestRef);

    await batch.commit();
  }
}