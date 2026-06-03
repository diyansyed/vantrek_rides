import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';

class DriverSubscribersScreen extends StatefulWidget {
  const DriverSubscribersScreen({super.key});

  @override
  State<DriverSubscribersScreen> createState() => _DriverSubscribersScreenState();
}

class _DriverSubscribersScreenState extends State<DriverSubscribersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _startChatWithUser(String userId, String userName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final chatService = ChatService();
      final chatId = await chatService.getOrCreateChat(
        userId: userId,
        driverId: currentUser.uid,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherPersonName: userName,
              otherPersonId: userId,
              isDriver: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSubscriber(String subscriptionId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Subscriber'),
        content: Text('Are you sure you want to remove $userName from your subscribers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    print('═══════════════════════════════════════');
    print('REMOVING SUBSCRIBER');
    print('Subscription ID: $subscriptionId');

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Driver not logged in');

      final subDoc = await _firestore
          .collection('drivers')
          .doc(currentUser.uid)
          .collection('subscribers')
          .doc(subscriptionId)
          .get();

      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }

      final subData = subDoc.data()!;
      final userId = subData['userId'];
      final driverId = currentUser.uid;

      print('User ID: $userId');
      print('Driver ID: $driverId');

      final batch = _firestore.batch();

      final mainSubRef = _firestore.collection('subscriptions').doc(subscriptionId);
      batch.delete(mainSubRef);
      print('✅ Deleting from: subscriptions/$subscriptionId');

      final userSubRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('driverSubscriptions')
          .doc(subscriptionId);
      batch.delete(userSubRef);
      print('✅ Deleting from: users/$userId/driverSubscriptions/$subscriptionId');

      final driverSubRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('subscribers')
          .doc(subscriptionId);
      batch.delete(driverSubRef);
      print('✅ Deleting from: drivers/$driverId/subscribers/$subscriptionId');

      final driverRef = _firestore.collection('drivers').doc(driverId);
      batch.set(driverRef, {
        'subscriberCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      print('✅ Decrementing subscriber count');

      await batch.commit();

      print('✅ SUBSCRIBER REMOVED - Deleted from all 3 locations!');
      print('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscriber removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ REMOVE SUBSCRIBER ERROR: $e');
      print('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing subscriber: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'active',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription accepted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _rejectSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
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
          title: const Text('My Subscribers'),
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
          'My Subscribers',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('drivers')
            .doc(currentUser.uid)
            .collection('subscribers')
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
                    'Error loading subscribers',
                    style: TextStyle(color: Colors.grey[600]),
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
              return _buildSubscriberCard(subscription.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubscriberCard(String subscriptionId, Map<String, dynamic> data) {
    final userId = data['userId'] ?? '';
    final status = data['status'] ?? 'pending';
    final userName = data['userName'] ?? 'User';
    final userPhone = data['userPhone'] ?? '';

    final monthlyFee = data['monthlyFee'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (userPhone.isNotEmpty)
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs $monthlyFee',
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
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectSubscription(subscriptionId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptSubscription(subscriptionId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'active') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startChatWithUser(userId, userName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removeSubscriber(subscriptionId, userName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.person_remove, size: 18),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = 'Active';
        break;
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'Pending';
        break;
      case 'rejected':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        label = 'Rejected';
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
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
                Icons.people_outline,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Subscribers Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Users who subscribe to your service will appear here',
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