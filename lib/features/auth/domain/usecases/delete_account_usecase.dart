import '../repositories/auth_repository.dart';

class DeleteAccountParams {
  final String deletionReason;

  DeleteAccountParams({required this.deletionReason});
}

/// Permanently deletes the signed-in driver's account, passing on the reason
/// they gave for leaving.
///
/// Returns the server's confirmation message; throws when the server refuses,
/// leaving the local session intact.
class DeleteAccountUseCase {
  final AuthRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<String> call(DeleteAccountParams params) {
    return repository.deleteAccount(deletionReason: params.deletionReason);
  }
}
