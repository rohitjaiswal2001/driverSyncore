import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String phone;

  /// Dial code with a leading '+', e.g. '+91'. Empty when the server has none.
  final String phoneCountryCode;
  final String role;
  final String companyName;
  final bool isVerified;
  final String token;
  final String? profileImage;

  const User({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    this.phoneCountryCode = '',
    required this.role,
    required this.companyName,
    required this.isVerified,
    required this.token,
    this.profileImage,
  });

  String get phoneNumber => phone;

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        phoneCountryCode,
        role,
        companyName,
        isVerified,
        token,
        profileImage,
      ];
}
