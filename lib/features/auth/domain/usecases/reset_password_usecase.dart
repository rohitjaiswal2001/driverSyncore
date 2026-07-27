import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;
  final String otp;
  final String password;
  final String passwordConfirmation;

  ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.password,
    required this.passwordConfirmation,
  });
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<String> call(ResetPasswordParams params) {
    return repository.resetPassword(
      email: params.email,
      otp: params.otp,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
    );
  }
}
