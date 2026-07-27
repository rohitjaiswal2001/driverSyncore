import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class RemoveProfileImageUseCase {
  final AuthRepository repository;

  RemoveProfileImageUseCase(this.repository);

  Future<User> call() {
    return repository.removeProfileImage();
  }
}
