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

/// Emitted while the logout request is in flight, i.e. between the tap and the
/// token actually being cleared. Kept separate from [AuthLoading] so the app
/// shell can show a blocking spinner above every route without also reacting to
/// the login / profile requests that share [AuthLoading].
class AuthLoggingOut extends AuthState {
  const AuthLoggingOut({required super.role});
}

class AuthLoggedOut extends AuthState {
  /// Set only when a deleted account's owner asked to create a new one, so the
  /// app shell can open registration instead of leaving them on login.
  final bool openRegister;

  const AuthLoggedOut({required super.role, this.openRegister = false});

  @override
  List<Object?> get props => [role, openRegister];
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

  const OtpVerificationRequired({required this.email, required super.role});

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

  const PasswordResetSuccess({required this.message, required super.role});

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

/// Emitted while the delete-account request is in flight. Kept separate from
/// [AuthLoading] and [AuthLoggingOut] so only the deletion page reacts to it.
class AccountDeleting extends AuthState {
  const AccountDeleting({required super.role});
}

/// The account is scheduled for deletion and the local session has been
/// cleared. Carries the server's own message, which the login screen shows;
/// [AuthLoggedOut] follows immediately and does the routing.
class AccountDeleted extends AuthState {
  final String message;

  const AccountDeleted({required this.message, required super.role});

  @override
  List<Object?> get props => [message, role];
}

/// The server refused the deletion. The session is untouched, so the driver
/// stays signed in and can retry.
class AccountDeleteFailure extends AuthState {
  final String errorMessage;

  const AccountDeleteFailure({required this.errorMessage, required super.role});

  @override
  List<Object?> get props => [errorMessage, role];
}
