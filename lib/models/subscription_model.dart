class DriverSubscription {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String driverId;
  final String driverName;
  final DateTime subscribedAt;
  final DateTime expiresAt;
  final SubscriptionStatus status;
  final double monthlyFee;
  final String? paymentMethod;
  final DateTime? lastPaymentDate;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  DriverSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.driverId,
    required this.driverName,
    required this.subscribedAt,
    required this.expiresAt,
    this.status = SubscriptionStatus.active,
    this.monthlyFee = 1500.0, // PKR
    this.paymentMethod,
    this.lastPaymentDate,
    this.cancelledAt,
    this.cancellationReason,
  });

  bool get isActive => status == SubscriptionStatus.active &&
      DateTime.now().isBefore(expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysRemaining => expiresAt.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'driverId': driverId,
      'driverName': driverName,
      'subscribedAt': subscribedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.name,
      'monthlyFee': monthlyFee,
      'paymentMethod': paymentMethod,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  factory DriverSubscription.fromMap(Map<String, dynamic> map) {
    return DriverSubscription(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      subscribedAt: map['subscribedAt'] != null
          ? DateTime.parse(map['subscribedAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : DateTime.now().add(const Duration(days: 30)),
      status: SubscriptionStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      monthlyFee: (map['monthlyFee'] ?? 1500.0).toDouble(),
      paymentMethod: map['paymentMethod'],
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.parse(map['cancelledAt'])
          : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  DriverSubscription copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? driverId,
    String? driverName,
    DateTime? subscribedAt,
    DateTime? expiresAt,
    SubscriptionStatus? status,
    double? monthlyFee,
    String? paymentMethod,
    DateTime? lastPaymentDate,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return DriverSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

enum SubscriptionStatus {
  active,      // Currently subscribed
  expired,     // Subscription ended
  cancelled,   // User cancelled
  pending,     // Payment pending
}