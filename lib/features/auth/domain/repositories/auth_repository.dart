import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithCredentials({
    required String email,
    required String password,
    required String role,
  });

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String role,
    required String companyName,
    required String password,
    required String passwordConfirmation,
  });

  Future<User> verifyOtp({required String email, required String otp});

  Future<String> resendOtp({required String email});

  Future<User> loginWithOtp({
    required String phoneNumber,
    required String role,
  });

  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  });

  Future<User?> getCachedUser();
  Future<void> logout();

  Future<User> getProfile();

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? companyName,
    String? profileImagePath,
  });

  Future<User> removeProfileImage();

  /// Permanently deletes the signed-in driver's account on the server and
  /// wipes the local session. Returns the server's confirmation message.
  ///
  /// [deletionReason] is the driver's own words, sent to the API as
  /// `deletion_reason`.
  ///
  /// Throws when the server refuses; the local session is left untouched in
  /// that case, so a failed deletion never strands the driver signed out of an
  /// account that still exists.
  Future<String> deleteAccount({required String deletionReason});
}
