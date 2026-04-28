import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class StartChatScreen extends ConsumerStatefulWidget {
  final bool isDriver;

  const StartChatScreen({
    super.key,
    required this.isDriver,
  });

  @override
  ConsumerState<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends ConsumerState<StartChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _availableChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableChats();
  }

  Future<void> _loadAvailableChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      if (widget.isDriver) {
        // Load driver's subscribers
        await _loadSubscribers(currentUser.uid);
      } else {
        // Load user's subscribed drivers
        await _loadSubscribedDrivers(currentUser.uid);
      }
    } catch (e) {
      print('Error loading available chats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubscribers(String driverId) async {
    // Get all active subscriptions where this driver is the driver
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .get();

    final List<Map<String, dynamic>> subscribers = [];

    for (var doc in subscriptions.docs) {
      final userId = doc.data()['userId'];
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        subscribers.add({
          'id': userId,
          'name': userDoc.data()?['name'] ?? 'User',
          'phone': userDoc.data()?['phoneNumber'] ?? '',
          'type': 'user',
        });
      }
    }

    setState(() {
      _availableChats = subscribers;
    });
  }

  Future<void> _loadSubscribedDrivers(String userId) async {
    // Get all active subscriptions where this user is the subscriber
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    final List<Map<String, dynamic>> drivers = [];

    for (var doc in subscriptions.docs) {
      final driverId = doc.data()['driverId'];
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();

      if (driverDoc.exists) {
        drivers.add({
          'id': driverId,
          'name': driverDoc.data()?['name'] ?? 'Driver',
          'phone': driverDoc.data()?['phoneNumber'] ?? '',
          'vehicleType': driverDoc.data()?['vehicleType'] ?? 'Car',
          'vehicleNumber': driverDoc.data()?['vehicleNumber'] ?? '',
          'type': 'driver',
        });
      }
    }

    setState(() {
      _availableChats = drivers;
    });
  }

  Future<void> _startChat(Map<String, dynamic> person) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final chatService = ChatService();

      if (widget.isDriver) {
        // Driver starting chat with user
        await chatService.createOrGetChat(
          userId: person['id'],
          driverId: currentUser.uid,
        );
      } else {
        // User starting chat with driver
        await chatService.createOrGetChat(
          userId: currentUser.uid,
          driverId: person['id'],
        );
      }

      // Navigate back - the chat will now appear in the list
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isDriver ? 'Start Chat with Subscriber' : 'Start Chat with Driver',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableChats.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadAvailableChats,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _availableChats.length,
          itemBuilder: (context, index) {
            final person = _availableChats[index];
            return _buildPersonCard(person);
          },
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
                widget.isDriver ? Icons.people_outline : Icons.local_taxi_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.isDriver ? 'No Subscribers Yet' : 'No Active Subscriptions',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isDriver
                  ? 'You don\'t have any subscribers yet. Users who subscribe to your service will appear here.'
                  : 'You haven\'t subscribed to any drivers yet. Subscribe to a driver to start chatting.',
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

  Widget _buildPersonCard(Map<String, dynamic> person) {
    final isDriver = person['type'] == 'driver';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _startChat(person),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                child: Text(
                  person['name'][0].toUpperCase(),
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
                      person['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isDriver && person['vehicleType'] != null)
                      Text(
                        '${person['vehicleType']} • ${person['vehicleNumber']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      Text(
                        person['phone'] ?? 'No phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              // Start Chat Button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}