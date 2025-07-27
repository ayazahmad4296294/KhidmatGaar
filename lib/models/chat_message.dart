import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
}

class ChatConversation {
  final String id;
  final String customerId;
  final String customerName;
  final String workerId;
  final String workerName;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool hasUnreadMessages;

  ChatConversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.workerName,
    required this.lastMessageTime,
    required this.lastMessage,
    this.hasUnreadMessages = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'workerId': workerId,
      'workerName': workerName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }

  factory ChatConversation.fromMap(
      Map<String, dynamic> map, String documentId) {
    return ChatConversation(
      id: documentId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] ?? '',
      hasUnreadMessages: map['hasUnreadMessages'] ?? false,
    );
  }
}
