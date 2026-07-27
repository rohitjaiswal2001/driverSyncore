import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams {
  final String email;
  final String otp;

  VerifyOtpParams({
    required this.email,
    required this.otp,
  });
}

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<User> call(VerifyOtpParams params) {
    return repository.verifyOtp(
      email: params.email,
      otp: params.otp,
    );
  }
}
