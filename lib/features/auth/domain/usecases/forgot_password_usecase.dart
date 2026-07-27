import '../repositories/auth_repository.dart';

class ForgotPasswordParams {
  final String email;

  ForgotPasswordParams({required this.email});
}

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<String> call(ForgotPasswordParams params) {
    return repository.forgotPassword(email: params.email);
  }
}
