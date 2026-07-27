import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithOtpParams {
  final String phoneNumber;
  final String role;

  LoginWithOtpParams({
    required this.phoneNumber,
    required this.role,
  });
}

class LoginWithOtpUseCase {
  final AuthRepository repository;

  LoginWithOtpUseCase(this.repository);

  Future<User> call(LoginWithOtpParams params) {
    return repository.loginWithOtp(
      phoneNumber: params.phoneNumber,
      role: params.role,
    );
  }
}
