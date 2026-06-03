import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String chatId;
  final String userId;
  final String driverId;
  final String userName;
  final String driverName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int userUnreadCount;
  final int driverUnreadCount;

  Chat({
    required this.chatId,
    required this.userId,
    required this.driverId,
    required this.userName,
    required this.driverName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.userUnreadCount = 0,
    this.driverUnreadCount = 0,
  });


  static String generateChatId(String userId, String driverId) {
    return 'user_${userId}_driver_$driverId';
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'] ?? '',
      userId: map['userId'] ?? '',
      driverId: map['driverId'] ?? '',
      userName: map['userName'] ?? '',
      driverName: map['driverName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      userUnreadCount: map['userUnreadCount'] ?? 0,
      driverUnreadCount: map['driverUnreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId': userId,
      'driverId': driverId,
      'userName': userName,
      'driverName': driverName,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'userUnreadCount': userUnreadCount,
      'driverUnreadCount': driverUnreadCount,
    };
  }

  Chat copyWith({
    String? chatId,
    String? userId,
    String? driverId,
    String? userName,
    String? driverName,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? userUnreadCount,
    int? driverUnreadCount,
  }) {
    return Chat(
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      userName: userName ?? this.userName,
      driverName: driverName ?? this.driverName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      userUnreadCount: userUnreadCount ?? this.userUnreadCount,
      driverUnreadCount: driverUnreadCount ?? this.driverUnreadCount,
    );
  }
}