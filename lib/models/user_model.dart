class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserType userType;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.userType,
    required this.createdAt,
  });


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'userType': userType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }


  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      userType: UserType.values.firstWhere(
            (type) => type.name == map['userType'],
        orElse: () => UserType.user,
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }


  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserType? userType,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum UserType {
  user,
  driver,
}