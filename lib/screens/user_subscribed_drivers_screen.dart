import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/driver_details_screen.dart';

class UserSubscribedDriversScreen extends StatefulWidget {
  const UserSubscribedDriversScreen({super.key});

  @override
  State<UserSubscribedDriversScreen> createState() => _UserSubscribedDriversScreenState();
}

class _UserSubscribedDriversScreenState extends State<UserSubscribedDriversScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _unsubscribe(String subscriptionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
      // Get subscription data to find userId and driverId
      final subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();

      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }

      final subData = subDoc.data()!;
      final userId = subData['userId'];
      final driverId = subData['driverId'];

      print('User ID: $userId');
      print('Driver ID: $driverId');

      // Delete from all 3 locations using batch
      final batch = _firestore.batch();

      // 1. Main subscriptions collection
      final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
      batch.delete(subRef);
      print('✅ Deleting from: subscriptions/$subscriptionId');

      // 2. User's driverSubscriptions
      final userSubRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('driverSubscriptions')
          .doc(subscriptionId);
      batch.delete(userSubRef);
      print('✅ Deleting from: users/$userId/driverSubscriptions/$subscriptionId');

      // 3. Driver's subscribers
      final driverSubRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('subscribers')
          .doc(subscriptionId);
      batch.delete(driverSubRef);
      print('✅ Deleting from: drivers/$driverId/subscribers/$subscriptionId');

      // 4. Decrement subscriber count
      final driverRef = _firestore.collection('drivers').doc(driverId);
      batch.set(driverRef, {
        'subscriberCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      print('✅ Decrementing subscriber count');

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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Drivers'),
        ),
        body: const Center(
          child: Text('Please login first'),
        ),
      );
    }

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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading drivers',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final subscriptions = snapshot.data?.docs ?? [];
          if (subscriptions.isEmpty) {
            return _buildEmptyState();
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

    // FIX: Changed from 'monthlyPrice' to 'monthlyFee'
    final monthlyPrice = data['monthlyFee'] ?? 0;

    print('═══════════════════════════════════════');
    print('DISPLAYING DRIVER CARD');
    print('Subscription ID: $subscriptionId');
    print('Driver ID: $driverId');
    print('Monthly Fee from data: $monthlyPrice');
    print('═══════════════════════════════════════');

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('drivers').doc(driverId).get(),
      builder: (context, driverSnapshot) {
        if (!driverSnapshot.hasData) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final driverData = driverSnapshot.data?.data() as Map<String, dynamic>?;
        if (driverData == null) {
          return const SizedBox.shrink();
        }
        final driverName = driverData['name'] ?? 'Driver';
        final vehicleType = driverData['vehicleType'] ?? 'Car';
        final vehicleNumber = driverData['vehicleNumber'] ?? 'N/A';
        final rating = (driverData['rating'] ?? 0.0).toDouble();
        final totalRides = driverData['totalRides'] ?? 0;
        final phoneNumber = driverData['phoneNumber'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverDetailsScreen(
                    driverId: driverId,
                    driverName: driverName,
                    vehicleType: vehicleType,
                    vehicleNumber: vehicleNumber,
                    rating: rating,
                    totalRides: totalRides,
                    phoneNumber: phoneNumber,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                        child: Text(
                          driverName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '$vehicleType • $vehicleNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '$rating ($totalRides rides)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${monthlyPrice.toString()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          Text(
                            'per month',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _unsubscribe(subscriptionId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Unsubscribe'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverDetailsScreen(
                                  driverId: driverId,
                                  driverName: driverName,
                                  vehicleType: vehicleType,
                                  vehicleNumber: vehicleNumber,
                                  rating: rating,
                                  totalRides: totalRides,
                                  phoneNumber: phoneNumber,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            const Text(
              'No Active Subscriptions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t subscribed to any drivers yet.\nFind and subscribe to drivers to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}