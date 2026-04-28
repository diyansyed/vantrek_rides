import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Subscribe to a driver
  /// Can be called by user OR by driver when accepting request
  Future<String> subscribeToDriver({
    required String driverId,
    required String driverName,
    String? userId,        // Optional: provided when driver accepts
    String? userName,      // Optional: provided when driver accepts
    String? userPhone,     // Optional: provided when driver accepts
    String paymentMethod = 'free',
  }) async {
    // Use provided userId or get from current user
    final String finalUserId;
    final String finalUserName;
    final String finalUserPhone;

    if (userId != null) {
      // Driver is adding subscriber (from accept request)
      finalUserId = userId;
      finalUserName = userName ?? 'User';
      finalUserPhone = userPhone ?? '';
    } else {
      // User is subscribing themselves
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      finalUserId = user.uid;
      finalUserName = userData['name'] ?? user.displayName ?? 'User';
      finalUserPhone = userData['phoneNumber'] ?? '';
    }

    // Check if already subscribed
    final existing = await _isUserSubscribedToDriver(finalUserId, driverId);
    if (existing) {
      throw Exception('Already subscribed to this driver');
    }

    final subscriptionId = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30)); // 1 month

    final subscription = DriverSubscription(
      id: subscriptionId,
      userId: finalUserId,
      userName: finalUserName,
      userPhone: finalUserPhone,
      driverId: driverId,
      driverName: driverName,
      subscribedAt: now,
      expiresAt: expiresAt,
      status: SubscriptionStatus.active,
      monthlyFee: 0.0, // Free for now
      paymentMethod: paymentMethod,
      lastPaymentDate: now,
    );

    final batch = _firestore.batch();

    // 1. Main subscriptions collection
    final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
    batch.set(subRef, subscription.toMap());

    // 2. User's subscriptions subcollection
    final userSubRef = _firestore
        .collection('users')
        .doc(finalUserId)
        .collection('driverSubscriptions')
        .doc(subscriptionId);
    batch.set(userSubRef, subscription.toMap());

    // 3. Driver's subscribers subcollection
    final driverSubRef = _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .doc(subscriptionId);
    batch.set(driverSubRef, subscription.toMap());

    // 4. Update driver's subscriber count (use set with merge to avoid update errors)
    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.set(driverRef, {
      'subscriberCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();

    return subscriptionId;
  }

  /// Internal helper to check subscription
  Future<bool> _isUserSubscribedToDriver(String userId, String driverId) async {
    // Check from driver's subscribers (more permissive in rules)
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('subscribers')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      // Check if not expired
      final subscription = DriverSubscription.fromMap(snapshot.docs.first.data());
      return subscription.isActive;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Check if user is subscribed to a driver
  Future<bool> isSubscribedToDriver(String driverId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check from driver's subscribers (more permissive in rules)
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('subscribers')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      // Check if not expired
      final subscription = DriverSubscription.fromMap(snapshot.docs.first.data());
      return subscription.isActive;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Get user's active subscriptions
  Future<List<DriverSubscription>> getUserSubscriptions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('driverSubscriptions')
        .get();

    final subscriptions = snapshot.docs
        .map((doc) => DriverSubscription.fromMap(doc.data()))
        .toList();

    // Sort by expiry date
    subscriptions.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

    return subscriptions;
  }

  /// Get driver's subscribers
  Future<List<DriverSubscription>> getDriverSubscribers(String driverId) async {
    final snapshot = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .where('status', isEqualTo: 'active')
        .get();

    final subscribers = snapshot.docs
        .map((doc) => DriverSubscription.fromMap(doc.data()))
        .toList();

    // Sort by subscribed date (newest first)
    subscribers.sort((a, b) => b.subscribedAt.compareTo(a.subscribedAt));

    return subscribers;
  }

  /// Get driver's active subscriber count
  Future<int> getDriverSubscriberCount(String driverId) async {
    final snapshot = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .where('status', isEqualTo: 'active')
        .get();

    // Filter out expired ones
    int activeCount = 0;
    for (var doc in snapshot.docs) {
      final sub = DriverSubscription.fromMap(doc.data());
      if (sub.isActive) activeCount++;
    }

    return activeCount;
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId, String reason) async {
    final batch = _firestore.batch();

    // Get subscription to find user and driver IDs
    final subDoc = await _firestore
        .collection('subscriptions')
        .doc(subscriptionId)
        .get();

    if (!subDoc.exists) throw Exception('Subscription not found');

    final subscription = DriverSubscription.fromMap(subDoc.data()!);

    final updateData = {
      'status': SubscriptionStatus.cancelled.name,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancellationReason': reason,
    };

    // Update main collection
    final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
    batch.update(subRef, updateData);

    // Update user's copy
    final userSubRef = _firestore
        .collection('users')
        .doc(subscription.userId)
        .collection('driverSubscriptions')
        .doc(subscriptionId);
    batch.update(userSubRef, updateData);

    // Update driver's copy
    final driverSubRef = _firestore
        .collection('drivers')
        .doc(subscription.driverId)
        .collection('subscribers')
        .doc(subscriptionId);
    batch.update(driverSubRef, updateData);

    // Decrement driver's subscriber count
    final driverRef = _firestore.collection('drivers').doc(subscription.driverId);
    batch.set(driverRef, {
      'subscriberCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Renew subscription (extend by 30 days)
  Future<void> renewSubscription(String subscriptionId) async {
    final batch = _firestore.batch();

    // Get subscription
    final subDoc = await _firestore
        .collection('subscriptions')
        .doc(subscriptionId)
        .get();

    if (!subDoc.exists) throw Exception('Subscription not found');

    final subscription = DriverSubscription.fromMap(subDoc.data()!);
    final newExpiryDate = subscription.expiresAt.add(const Duration(days: 30));

    final updateData = {
      'expiresAt': newExpiryDate.toIso8601String(),
      'status': SubscriptionStatus.active.name,
      'lastPaymentDate': DateTime.now().toIso8601String(),
    };

    // Update all 3 locations
    final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
    batch.update(subRef, updateData);

    final userSubRef = _firestore
        .collection('users')
        .doc(subscription.userId)
        .collection('driverSubscriptions')
        .doc(subscriptionId);
    batch.update(userSubRef, updateData);

    final driverSubRef = _firestore
        .collection('drivers')
        .doc(subscription.driverId)
        .collection('subscribers')
        .doc(subscriptionId);
    batch.update(driverSubRef, updateData);

    await batch.commit();
  }

  /// Get subscription details
  Future<DriverSubscription?> getSubscription(String subscriptionId) async {
    final doc = await _firestore
        .collection('subscriptions')
        .doc(subscriptionId)
        .get();

    if (!doc.exists) return null;
    return DriverSubscription.fromMap(doc.data()!);
  }

  /// Get specific subscription between user and driver
  Future<DriverSubscription?> getSubscriptionByUserAndDriver(
      String userId,
      String driverId,
      ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('driverSubscriptions')
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DriverSubscription.fromMap(snapshot.docs.first.data());
  }

  /// Stream of user's subscriptions (real-time)
  Stream<List<DriverSubscription>> streamUserSubscriptions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('driverSubscriptions')
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs
          .map((doc) => DriverSubscription.fromMap(doc.data()))
          .toList();

      subs.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      return subs;
    });
  }

  /// Stream of driver's subscribers (real-time)
  Stream<List<DriverSubscription>> streamDriverSubscribers(String driverId) {
    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('subscribers')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs
          .map((doc) => DriverSubscription.fromMap(doc.data()))
          .toList();

      subs.sort((a, b) => b.subscribedAt.compareTo(a.subscribedAt));
      return subs;
    });
  }
}