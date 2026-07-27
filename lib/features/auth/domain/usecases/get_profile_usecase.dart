import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  Future<User> call() {
    return repository.getProfile();
  }
}
