import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RoleChanged extends AuthEvent {
  final String role;

  const RoleChanged(this.role);

  @override
  List<Object?> get props => [role];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String companyName;
  final String password;
  final String passwordConfirmation;

  const RegisterSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.companyName,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    phone,
    role,
    companyName,
    password,
    passwordConfirmation,
  ];
}

class VerifyOtpSubmitted extends AuthEvent {
  final String email;
  final String otp;

  const VerifyOtpSubmitted({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class LoginWithOtpSubmitted extends AuthEvent {
  final String phoneNumber;

  const LoginWithOtpSubmitted({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;

  const ForgotPasswordSubmitted({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordSubmitted extends AuthEvent {
  final String email;
  final String otp;
  final String password;
  final String passwordConfirmation;

  const ResetPasswordSubmitted({
    required this.email,
    required this.otp,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props => [email, otp, password, passwordConfirmation];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ResendOtpRequested extends AuthEvent {
  final String email;

  const ResendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class GetProfileDetails extends AuthEvent {
  const GetProfileDetails();
}

class UpdateProfileSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String? companyName;
  final String? profileImagePath;

  const UpdateProfileSubmitted({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.companyName,
    this.profileImagePath,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, companyName, profileImagePath];
}

class RemoveProfileImageSubmitted extends AuthEvent {
  const RemoveProfileImageSubmitted();
}
