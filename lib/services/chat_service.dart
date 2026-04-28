import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get existing chat between user and driver
  Future<String> createOrGetChat({
    required String userId,
    required String driverId,
  }) async {
    // Create chat ID (always in same order for consistency)
    final chatId = 'user_${userId}_driver_$driverId';

    // Check if chat already exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Fetch user and driver details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();

      final userName = userDoc.data()?['name'] ?? 'User';
      final driverName = driverDoc.data()?['name'] ?? 'Driver';

      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'userId': userId,
        'driverId': driverId,
        'userName': userName,
        'driverName': driverName,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'userUnreadCount': 0,
        'driverUnreadCount': 0,
      });
    }

    return chatId;
  }

  // Alias for compatibility
  Future<String> getOrCreateChat({
    required String userId,
    required String driverId,
  }) async {
    return createOrGetChat(userId: userId, driverId: driverId);
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required bool isDriver,
    String? text, // Alias for compatibility
    String? receiverId, // For compatibility
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final messageText = message.isNotEmpty ? message : (text ?? '');

    // Add message to messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'isDriver': isDriver,
    });

    // Update chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      // Increment unread count for the other person
      if (isDriver) 'userUnreadCount': FieldValue.increment(1),
      if (!isDriver) 'driverUnreadCount': FieldValue.increment(1),
    });
  }

  // Mark messages as read
  Future<void> markAsRead({
    required String chatId,
    required bool isDriver,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      if (isDriver) 'driverUnreadCount': 0,
      if (!isDriver) 'userUnreadCount': 0,
    });
  }

  // Alias for compatibility
  Future<void> markMessagesAsRead({
    required String chatId,
    required bool isDriver,
  }) async {
    return markAsRead(chatId: chatId, isDriver: isDriver);
  }

  // Get chats for current user
  Stream<List<Map<String, dynamic>>> getChats({required bool isDriver}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final field = isDriver ? 'driverId' : 'userId';

    return _firestore
        .collection('chats')
        .where(field, isEqualTo: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'chatId': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Get messages for a chat
  Stream<List<Map<String, dynamic>>> getMessages({required String chatId}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'messageId': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete chat document
    await _firestore.collection('chats').doc(chatId).delete();
  }
}