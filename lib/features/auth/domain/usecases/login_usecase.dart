import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  final String role;

  LoginParams({
    required this.email,
    required this.password,
    required this.role,
  });
}

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(LoginParams params) {
    return repository.loginWithCredentials(
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}
