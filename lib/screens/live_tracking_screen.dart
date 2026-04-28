import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_details_screen.dart';
import 'driver_live_location_map_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _unsubscribe(String subscriptionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsubscribe'),
        content: const Text('Are you sure you want to unsubscribe from this driver?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    print('═══════════════════════════════════════');
    print('UNSUBSCRIBING');
    print('Subscription ID: $subscriptionId');

    try {
      // STEP 1: Get subscription data to find userId and driverId
      final subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();

      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }

      final subData = subDoc.data()!;
      final userId = subData['userId'];
      final driverId = subData['driverId'];

      print('User ID: $userId');
      print('Driver ID: $driverId');

      // STEP 2: Delete from all 3 locations using batch
      final batch = _firestore.batch();

      // 1. Delete from main subscriptions collection
      final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
      batch.delete(subRef);
      print('✅ Deleting from: subscriptions/$subscriptionId');

      // 2. Delete from user's driverSubscriptions subcollection
      final userSubRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('driverSubscriptions')
          .doc(subscriptionId);
      batch.delete(userSubRef);
      print('✅ Deleting from: users/$userId/driverSubscriptions/$subscriptionId');

      // 3. Delete from driver's subscribers subcollection
      final driverSubRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('subscribers')
          .doc(subscriptionId);
      batch.delete(driverSubRef);
      print('✅ Deleting from: drivers/$driverId/subscribers/$subscriptionId');

      // 4. Decrement driver's subscriber count
      final driverRef = _firestore.collection('drivers').doc(driverId);
      batch.set(driverRef, {
        'subscriberCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      print('✅ Decrementing subscriber count for driver');

      // STEP 3: Commit all changes atomically
      await batch.commit();

      print('✅ UNSUBSCRIBE SUCCESSFUL - Deleted from all 3 locations!');
      print('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsubscribed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ UNSUBSCRIBE ERROR: $e');
      print('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unsubscribing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewDriverLocation(String driverId, String driverName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverLiveLocationMapScreen(
          driverId: driverId,
          driverName: driverName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔴🔴🔴 LIVE TRACKING SCREEN BUILD CALLED 🔴🔴🔴');

    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    print('👤 Current user ID: ${user.uid}');
    print('📍 Querying: users/${user.uid}/driverSubscriptions');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Drivers',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIX: Query from user's driverSubscriptions subcollection
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('driverSubscriptions')
            .snapshots(),
        builder: (context, snapshot) {
          print('═══════════════════════════════════════');
          print('STREAM BUILDER STATE');
          print('Connection state: ${snapshot.connectionState}');
          print('Has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
          }
          print('Has data: ${snapshot.hasData}');
          if (snapshot.hasData) {
            print('Number of documents: ${snapshot.data?.docs.length}');
            for (var doc in snapshot.data!.docs) {
              print('  Doc ID: ${doc.id}');
              print('  Doc data: ${doc.data()}');
            }
          }
          print('═══════════════════════════════════════');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final subscriptions = snapshot.data?.docs ?? [];
          if (subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No Active Subscriptions', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Subscribe to drivers to track them', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              final data = subscription.data() as Map<String, dynamic>;
              return _buildDriverCard(subscription.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(String subscriptionId, Map<String, dynamic> data) {
    final driverId = data['driverId'] ?? '';
    final driverName = data['driverName'] ?? 'Driver';

    // DEBUG: Print all subscription data
    print('═══════════════════════════════════════');
    print('SUBSCRIPTION DATA FOR: $subscriptionId');
    print('Full data: $data');
    print('monthlyFee field: ${data['monthlyFee']}');
    print('monthlyPrice field: ${data['monthlyPrice']}');
    print('price field: ${data['price']}');
    print('fee field: ${data['fee']}');
    print('═══════════════════════════════════════');

    // Try different possible field names
    final monthlyFee = data['monthlyFee'] ??
        data['monthlyPrice'] ??
        data['price'] ??
        data['fee'] ??
        0;

    print('Final monthlyFee value: $monthlyFee');

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('drivers').doc(driverId).get(),
      builder: (context, driverSnapshot) {
        if (!driverSnapshot.hasData) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final driverData = driverSnapshot.data?.data() as Map<String, dynamic>?;
        final vehicleType = driverData?['vehicleType'] ?? 'van';
        final vehicleNumber = driverData?['vehicleNumber'] ?? 'abs1234';
        final rating = (driverData?['rating'] ?? 0.0).toDouble();
        final totalRides = driverData?['totalRides'] ?? 0;
        final isOnline = driverData?['isOnline'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverDetailsScreen(
                        driverId: driverId,
                        driverName: driverName,
                        vehicleType: vehicleType,
                        vehicleNumber: vehicleNumber,
                        rating: rating,
                        totalRides: totalRides,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF2196F3),
                        child: Text(
                          driverName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('$vehicleType • $vehicleNumber', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${rating.toStringAsFixed(1)} ($totalRides rides)', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rs $monthlyFee', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
                          Text('per month', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isOnline ? Colors.green[200]! : Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online - Location sharing' : 'Offline',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOnline ? Colors.green[700] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _unsubscribe(subscriptionId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Unsubscribe'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isOnline ? () => _viewDriverLocation(driverId, driverName) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text(isOnline ? 'View Location' : 'Offline', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}