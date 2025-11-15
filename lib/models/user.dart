class User {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final String? profilePicture;
  final bool isVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.profilePicture,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];
    DateTime createdAt;
    if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue)?.toLocal() ?? DateTime.now();
    } else if (createdAtValue is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue, isUtc: true).toLocal();
    } else {
      createdAt = DateTime.now();
    }

    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      role: (json['role'] ?? 'user').toString(),
      profilePicture: json['profilePicture']?.toString(),
      isVerified: (json['isVerified'] ?? json['verified'] ?? false) == true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'profilePicture': profilePicture,
      'isVerified': isVerified,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
