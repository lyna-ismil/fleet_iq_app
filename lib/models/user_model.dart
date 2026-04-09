class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? profilePicture;
  final String? cinImageUrl;
  final String? licenseImageUrl;
  final bool isVerified;
  final bool isVerified;
  final bool isBlacklisted;
  final int nbrFoisAllocation;
  final int age;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.profilePicture,
    this.cinImageUrl,
    this.licenseImageUrl,
    this.isVerified = false,
    this.isBlacklisted = false,
    this.nbrFoisAllocation = 0,
    this.age = 30,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both wrapped {"user": {...}} and flat {...} responses
    final data = json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;
    return UserModel(
      id: data['_id'] ?? data['id'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['num_phone'] as String?,
      profilePicture: data['profile_picture'] as String?,
      cinImageUrl: data['cinImageUrl'] as String?,
      licenseImageUrl: data['licenseImageUrl'] as String?,
      licenseImageUrl: data['licenseImageUrl'] as String?,
      isVerified: data['isVerified'] ?? false,
      isBlacklisted: data['isBlacklisted'] ?? false,
      nbrFoisAllocation: data['nbrFoisAllocation'] ?? 0,
      age: data['age'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'num_phone': phone,
      'profile_picture': profilePicture,
      'cinImageUrl': cinImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'isVerified': isVerified,
      'isBlacklisted': isBlacklisted,
      'nbrFoisAllocation': nbrFoisAllocation,
      'age': age,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? profilePicture,
    String? cinImageUrl,
    String? licenseImageUrl,
    bool? isVerified,
    bool? isBlacklisted,
    int? nbrFoisAllocation,
    int? age,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
      cinImageUrl: cinImageUrl ?? this.cinImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      nbrFoisAllocation: nbrFoisAllocation ?? this.nbrFoisAllocation,
      age: age ?? this.age,
    );
  }
}
