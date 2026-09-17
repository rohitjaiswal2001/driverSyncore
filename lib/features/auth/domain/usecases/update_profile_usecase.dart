import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class UpdateProfileParams {
  final String firstName;
  final String lastName;
  final String phone;
  final String phoneCountryCode;
  final String? companyName;
  final String? profileImagePath;

  UpdateProfileParams({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.phoneCountryCode,
    this.companyName,
    this.profileImagePath,
  });
}

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<User> call(UpdateProfileParams params) {
    return repository.updateProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      phone: params.phone,
      phoneCountryCode: params.phoneCountryCode,
      companyName: params.companyName,
      profileImagePath: params.profileImagePath,
    );
  }
}
