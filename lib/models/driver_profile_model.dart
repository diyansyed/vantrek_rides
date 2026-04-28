enum VehicleType {
  car,
  van,
  bike,
  rickshaw,
  suv,
}

enum SubscriptionStatus {
  active,
  expired,
  pending,
  cancelled,
}

class DriverProfile {
  final String driverId;
  final VehicleType vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final String licenseNumber;
  final String serviceInstitutionId;
  final String serviceInstitutionName;
  final DateTime registeredAt;
  final double rating;
  final int totalRides;
  final bool isApproved;
  final bool isOnline; // Shares location with subscribers when true

  // Subscription fields
  final SubscriptionStatus subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final double monthlyFee;
  final bool autoRenew;

  // Subscribers (users who pay to see this driver's location)
  final int subscriberCount;

  // Earnings
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double totalEarnings;

  DriverProfile({
    required this.driverId,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.serviceInstitutionId,
    required this.serviceInstitutionName,
    required this.registeredAt,
    this.rating = 0.0,
    this.totalRides = 0,
    this.isApproved = true, // Auto-approved for now
    this.isOnline = false,
    this.subscriptionStatus = SubscriptionStatus.pending,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.monthlyFee = 1500.0, // PKR 1500/month default
    this.autoRenew = false,
    this.subscriberCount = 0,
    this.todayEarnings = 0.0,
    this.weekEarnings = 0.0,
    this.monthEarnings = 0.0,
    this.totalEarnings = 0.0,
  });

  // Check if subscription is active
  bool get isSubscriptionActive {
    if (subscriptionStatus != SubscriptionStatus.active) return false;
    if (subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  // Days remaining in subscription
  int get daysRemaining {
    if (subscriptionEndDate == null) return 0;
    final difference = subscriptionEndDate!.difference(DateTime.now());
    return difference.inDays;
  }

  // Vehicle type display name
  String get vehicleTypeDisplay {
    switch (vehicleType) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.rickshaw:
        return 'Rickshaw';
      case VehicleType.suv:
        return 'SUV';
    }
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleType': vehicleType.name,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'serviceInstitutionId': serviceInstitutionId,
      'serviceInstitutionName': serviceInstitutionName,
      'registeredAt': registeredAt.toIso8601String(),
      'rating': rating,
      'totalRides': totalRides,
      'isApproved': isApproved,
      'isOnline': isOnline,
      'subscriptionStatus': subscriptionStatus.name,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'monthlyFee': monthlyFee,
      'autoRenew': autoRenew,
      'subscriberCount': subscriberCount,
      'todayEarnings': todayEarnings,
      'weekEarnings': weekEarnings,
      'monthEarnings': monthEarnings,
      'totalEarnings': totalEarnings,
    };
  }

  // Create from Firestore
  factory DriverProfile.fromMap(Map<String, dynamic> map) {
    return DriverProfile(
      driverId: map['driverId'] ?? '',
      vehicleType: VehicleType.values.firstWhere(
            (e) => e.name == map['vehicleType'],
        orElse: () => VehicleType.car,
      ),
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      serviceInstitutionId: map['serviceInstitutionId'] ?? '',
      serviceInstitutionName: map['serviceInstitutionName'] ?? '',
      registeredAt: DateTime.parse(map['registeredAt']),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      isApproved: map['isApproved'] ?? true,
      isOnline: map['isOnline'] ?? false,
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
            (e) => e.name == map['subscriptionStatus'],
        orElse: () => SubscriptionStatus.pending,
      ),
      subscriptionStartDate: map['subscriptionStartDate'] != null
          ? DateTime.parse(map['subscriptionStartDate'])
          : null,
      subscriptionEndDate: map['subscriptionEndDate'] != null
          ? DateTime.parse(map['subscriptionEndDate'])
          : null,
      monthlyFee: (map['monthlyFee'] ?? 1500.0).toDouble(),
      autoRenew: map['autoRenew'] ?? false,
      subscriberCount: map['subscriberCount'] ?? 0,
      todayEarnings: (map['todayEarnings'] ?? 0.0).toDouble(),
      weekEarnings: (map['weekEarnings'] ?? 0.0).toDouble(),
      monthEarnings: (map['monthEarnings'] ?? 0.0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
    );
  }

  // Copy with method for updates
  DriverProfile copyWith({
    String? driverId,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? vehicleNumber,
    String? licenseNumber,
    String? serviceInstitutionId,
    String? serviceInstitutionName,
    DateTime? registeredAt,
    double? rating,
    int? totalRides,
    bool? isApproved,
    bool? isOnline,
    SubscriptionStatus? subscriptionStatus,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    double? monthlyFee,
    bool? autoRenew,
    int? subscriberCount,
    double? todayEarnings,
    double? weekEarnings,
    double? monthEarnings,
    double? totalEarnings,
  }) {
    return DriverProfile(
      driverId: driverId ?? this.driverId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      serviceInstitutionId: serviceInstitutionId ?? this.serviceInstitutionId,
      serviceInstitutionName: serviceInstitutionName ?? this.serviceInstitutionName,
      registeredAt: registeredAt ?? this.registeredAt,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isApproved: isApproved ?? this.isApproved,
      isOnline: isOnline ?? this.isOnline,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      autoRenew: autoRenew ?? this.autoRenew,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      weekEarnings: weekEarnings ?? this.weekEarnings,
      monthEarnings: monthEarnings ?? this.monthEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }
}