class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String driverId;
  final String driverName;
  final String institutionId;
  final String institutionName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime requestedAt;
  final RideRequestStatus status;
  final String? rejectionReason;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.driverId,
    required this.driverName,
    required this.institutionId,
    required this.institutionName,
    this.pickupLocation = '',
    this.dropoffLocation = '',
    required this.requestedAt,
    this.status = RideRequestStatus.pending,
    this.rejectionReason,
    this.acceptedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'driverId': driverId,
      'driverName': driverName,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'rejectionReason': rejectionReason,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      institutionId: map['institutionId'] ?? '',
      institutionName: map['institutionName'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      dropoffLocation: map['dropoffLocation'] ?? '',
      requestedAt: map['requestedAt'] != null
          ? DateTime.parse(map['requestedAt'])
          : DateTime.now(),
      status: RideRequestStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => RideRequestStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.parse(map['acceptedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  RideRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? driverId,
    String? driverName,
    String? institutionId,
    String? institutionName,
    String? pickupLocation,
    String? dropoffLocation,
    DateTime? requestedAt,
    RideRequestStatus? status,
    String? rejectionReason,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum RideRequestStatus {
  pending,    // Waiting for driver response
  accepted,   // Driver accepted
  rejected,   // Driver rejected
  completed,  // Ride completed
  cancelled,  // User cancelled
}