import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firstName,
    super.lastName,
    required super.email,
    required super.phone,
    required super.role,
    required super.companyName,
    required super.isVerified,
    required super.token,
    super.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // If user block is nested inside root response
    final userMap = json['user'] != null 
        ? json['user'] as Map<String, dynamic> 
        : json['data'] != null
            ? json['data'] as Map<String, dynamic>
            : json;
        
    final userToken = token ?? json['token'] as String? ?? '';

    // Safe parsing for id
    final idStr = userMap['id']?.toString() ?? '';

    // Safe parsing for is_verified (can be bool, dynamic String "1" or int 1)
    final isVerifiedRaw = userMap['is_verified'];
    bool isVerified = false;
    if (isVerifiedRaw is bool) {
      isVerified = isVerifiedRaw;
    } else if (isVerifiedRaw is String) {
      isVerified = isVerifiedRaw == '1' || isVerifiedRaw.toLowerCase() == 'true';
    } else if (isVerifiedRaw is num) {
      isVerified = isVerifiedRaw == 1;
    }

    return UserModel(
      id: idStr,
      firstName: userMap['first_name'] as String? ?? '',
      lastName: userMap['last_name'] as String?,
      email: userMap['email'] as String? ?? '',
      phone: userMap['phone'] as String? ?? userMap['phoneNumber'] as String? ?? '',
      // Driver-only app: the login/profile payload does not always carry a
      // role, and an empty one here is what the API rejects on the next
      // login. Fall back rather than propagate a blank role.
      role: (userMap['role'] as String?)?.trim().isNotEmpty == true
          ? userMap['role'] as String
          : 'driver',
      companyName: userMap['company_name'] as String? ?? '',
      isVerified: isVerified,
      token: userToken,
      profileImage: userMap['profile_image'] as String? ?? userMap['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'company_name': companyName,
      'is_verified': isVerified,
      'token': token,
      'profile_image': profileImage,
    };
  }
}
