import '../repositories/auth_repository.dart';

class RegisterParams {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String companyName;
  final String password;
  final String passwordConfirmation;

  RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.companyName,
    required this.password,
    required this.passwordConfirmation,
  });
}

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<void> call(RegisterParams params) {
    return repository.register(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      phone: params.phone,
      role: params.role,
      companyName: params.companyName,
      password: params.password,
      passwordConfirmation: params.passwordConfirmation,
    );
  }
}
