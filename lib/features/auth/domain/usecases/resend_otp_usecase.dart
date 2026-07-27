import '../repositories/auth_repository.dart';

class ResendOtpParams {
  final String email;

  ResendOtpParams({required this.email});
}

class ResendOtpUseCase {
  final AuthRepository repository;

  ResendOtpUseCase(this.repository);

  Future<String> call(ResendOtpParams params) {
    return repository.resendOtp(email: params.email);
  }
}
