import 'package:cloud_firestore/cloud_firestore.dart';

class PriceNegotiation {
  final String id;
  final String bookingId;
  final String workerId;
  final String customerId;
  final String serviceName;
  final double initialPrice;
  final double minAcceptablePrice; // Worker's minimum
  final double maxAcceptablePrice; // Customer's maximum
  final double currentOffer;
  final String offerBy; // 'worker' or 'customer'
  final bool isAccepted;
  final bool isRejected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<NegotiationOffer> offerHistory;

  PriceNegotiation({
    required this.id,
    required this.bookingId,
    required this.workerId,
    required this.customerId,
    required this.serviceName,
    required this.initialPrice,
    required this.minAcceptablePrice,
    required this.maxAcceptablePrice,
    required this.currentOffer,
    required this.offerBy,
    required this.isAccepted,
    required this.isRejected,
    required this.createdAt,
    required this.updatedAt,
    required this.offerHistory,
  });

  factory PriceNegotiation.fromMap(Map<String, dynamic> map, String id) {
    List<NegotiationOffer> history = [];
    if (map['offerHistory'] != null) {
      List<dynamic> historyData = map['offerHistory'] as List<dynamic>;
      history =
          historyData.map((item) => NegotiationOffer.fromMap(item)).toList();
    }

    return PriceNegotiation(
      id: id,
      bookingId: map['bookingId'] ?? '',
      workerId: map['workerId'] ?? '',
      customerId: map['customerId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      initialPrice: (map['initialPrice'] ?? 0.0).toDouble(),
      minAcceptablePrice: (map['minAcceptablePrice'] ?? 0.0).toDouble(),
      maxAcceptablePrice: (map['maxAcceptablePrice'] ?? 0.0).toDouble(),
      currentOffer: (map['currentOffer'] ?? 0.0).toDouble(),
      offerBy: map['offerBy'] ?? 'worker',
      isAccepted: map['isAccepted'] ?? false,
      isRejected: map['isRejected'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      offerHistory: history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'workerId': workerId,
      'customerId': customerId,
      'serviceName': serviceName,
      'initialPrice': initialPrice,
      'minAcceptablePrice': minAcceptablePrice,
      'maxAcceptablePrice': maxAcceptablePrice,
      'currentOffer': currentOffer,
      'offerBy': offerBy,
      'isAccepted': isAccepted,
      'isRejected': isRejected,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'offerHistory': offerHistory.map((offer) => offer.toMap()).toList(),
    };
  }
}

class NegotiationOffer {
  final double amount;
  final String by; // 'worker' or 'customer'
  final DateTime timestamp;
  final String? message;

  NegotiationOffer({
    required this.amount,
    required this.by,
    required this.timestamp,
    this.message,
  });

  factory NegotiationOffer.fromMap(Map<String, dynamic> map) {
    return NegotiationOffer(
      amount: (map['amount'] ?? 0.0).toDouble(),
      by: map['by'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'by': by,
      'timestamp': Timestamp.fromDate(timestamp),
      'message': message,
    };
  }
}
