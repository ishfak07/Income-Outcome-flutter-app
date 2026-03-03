/// User model for Rumi Ishi Expense Tracker.
/// Represents a registered user with verified email.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isEmailVerified;
  final DateTime createdAt;
  final String? profilePhotoUrl;
  final String? avatarId;
  final String? bio;
  final String currency;
  final double monthlyBudget;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.isEmailVerified = false,
    required this.createdAt,
    this.profilePhotoUrl,
    this.avatarId,
    this.bio,
    this.currency = '\$',
    this.monthlyBudget = 0,
  });

  /// Create UserModel from Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isEmailVerified:
          map['isEmailVerified'] ?? map['isPhoneVerified'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      profilePhotoUrl: map['profilePhotoUrl'],
      avatarId: map['avatarId'],
      bio: map['bio'],
      currency: map['currency'] ?? '\$',
      monthlyBudget: (map['monthlyBudget'] ?? 0).toDouble(),
    );
  }

  /// Convert UserModel to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'profilePhotoUrl': profilePhotoUrl,
      'avatarId': avatarId,
      'bio': bio,
      'currency': currency,
      'monthlyBudget': monthlyBudget,
    };
  }

  /// Create a copy with optional overrides.
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    bool? isEmailVerified,
    String? profilePhotoUrl,
    String? avatarId,
    String? bio,
    String? currency,
    double? monthlyBudget,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      avatarId: avatarId ?? this.avatarId,
      bio: bio ?? this.bio,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
