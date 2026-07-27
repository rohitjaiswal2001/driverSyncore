import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  final String role;
  
  const AuthState({required this.role});

  @override
  List<Object?> get props => [role];
}

class AuthInitial extends AuthState {
  const AuthInitial({required super.role});
}

class AuthLoading extends AuthState {
  const AuthLoading({required super.role});
}

class AuthSuccess extends AuthState {
  final User user;

  AuthSuccess({required this.user}) : super(role: user.role);

  @override
  List<Object?> get props => [user, role];
}

class OtpVerificationRequired extends AuthState {
  final String email;

  const OtpVerificationRequired({
    required this.email,
    required super.role,
  });

  @override
  List<Object?> get props => [email, role];
}

class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure({required super.role, required this.errorMessage});

  @override
  List<Object?> get props => [role, errorMessage];
}

class ForgotPasswordEmailSent extends AuthState {
  final String email;
  final String message;

  const ForgotPasswordEmailSent({
    required this.email,
    required this.message,
    required super.role,
  });

  @override
  List<Object?> get props => [email, message, role];
}

class PasswordResetSuccess extends AuthState {
  final String message;

  const PasswordResetSuccess({
    required this.message,
    required super.role,
  });

  @override
  List<Object?> get props => [message, role];
}

class OtpResentSuccess extends AuthState {
  final String email;
  final String message;

  const OtpResentSuccess({
    required this.email,
    required this.message,
    required super.role,
  });

  @override
  List<Object?> get props => [email, message, role];
}

