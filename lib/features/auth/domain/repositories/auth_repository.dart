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

  Future<User> verifyOtp({
    required String email,
    required String otp,
  });

  Future<String> resendOtp({
    required String email,
  });

  Future<User> loginWithOtp({
    required String phoneNumber,
    required String role,
  });

  Future<String> forgotPassword({
    required String email,
  });

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
}
