import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _sharedPreferences;

  AuthRepositoryImpl(this._apiClient, this._sharedPreferences);

  // Prefers the top-level `message`, falling back to the first field error
  // in `errors` (Laravel validation shape) since some endpoints return
  // status: false with only field errors and no top-level message.
  String _extractErrorMessage(Map<String, dynamic> data, String fallback) {
    final message = data['message'] as String?;
    if (message != null && message.isNotEmpty) return message;

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }
    return fallback;
  }

  @override
  Future<User> loginWithCredentials({
    required String email,
    required String password,
    required String role,
  }) async {
    // API endpoint: /login
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {'email': email, 'password': password, 'role': role.toLowerCase()},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Invalid credentials'));
      }
      final userModel = UserModel.fromJson(data);
      // Set the authentication token for subsequent requests
      _apiClient.setAuthToken(userModel.token);
      await _cacheUser(userModel);
      return userModel;
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String role,
    required String companyName,
    required String password,
    required String passwordConfirmation,
  }) async {
    // API endpoint: /register
    final Map<String, dynamic> requestData = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role.toLowerCase(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    };

    if (phone.trim().isNotEmpty) {
      requestData['phone'] = phone.trim();
    }
    if (companyName.trim().isNotEmpty) {
      requestData['company_name'] = companyName.trim();
    }

    final response = await _apiClient.post(
      ApiConstants.register,
      data: requestData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final status = data['status'];
      if (status == false) {
        throw AuthException(_extractErrorMessage(data, 'Registration failed'));
      }
      return;
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<User> verifyOtp({required String email, required String otp}) async {
    // API endpoint: /verify-otp
    final response = await _apiClient.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Invalid OTP'));
      }
      final userModel = UserModel.fromJson(data);
      // Set the authentication token for subsequent requests
      _apiClient.setAuthToken(userModel.token);
      await _cacheUser(userModel);
      return userModel;
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<String> resendOtp({required String email}) async {
    // API endpoint: /resend-otp
    final response = await _apiClient.post(
      ApiConstants.resendOtp,
      data: {'email': email},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['status'] ?? data['success'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Failed to resend OTP'));
      }
      return data['message'] as String? ?? 'OTP resent successfully.';
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<User> loginWithOtp({
    required String phoneNumber,
    required String role,
  }) async {
    // Simulate legacy API network call delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (phoneNumber.trim().isEmpty || phoneNumber.length < 10) {
      throw Exception('Please enter a valid 10-digit mobile number');
    }

    final userModel = UserModel(
      id: 'usr_mock_otp_54321',
      firstName: 'OTP User',
      lastName: '',
      email: 'otpuser@syntracore.com',
      phone: phoneNumber,
      role: role,
      companyName: 'Mock Company',
      isVerified: true,
      token: 'jwt_mock_token_otp_abc_syntracore_112233',
    );
    _apiClient.setAuthToken(userModel.token);
    await _cacheUser(userModel);
    return userModel;
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    // API endpoint: /forgot-password
    final response = await _apiClient.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['status'] ?? data['success'];
      if (success == false) {
        throw AuthException(
          _extractErrorMessage(data, 'Failed to send reset code'),
        );
      }
      return data['message'] as String? ??
          'Password reset code sent to your email.';
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    // API endpoint: /reset-password
    final response = await _apiClient.post(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['status'] ?? data['success'];
      if (success == false) {
        throw AuthException(
          _extractErrorMessage(data, 'Failed to reset password'),
        );
      }
      return data['message'] as String? ?? 'Password reset successfully.';
    }

    throw ServerException('Invalid response format from server');
  }

  static const String _userKey = 'cached_user';
  static const String _authTokenKey = 'auth_token';

  Future<void> _cacheUser(User user) async {
    final userModel = UserModel(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      companyName: user.companyName,
      isVerified: user.isVerified,
      token: user.token,
      profileImage: user.profileImage,
    );
    if (user.token.isNotEmpty) {
      await _sharedPreferences.setString(_authTokenKey, user.token);
      _apiClient.setAuthToken(user.token);
    }
    await _sharedPreferences.setString(_userKey, jsonEncode(userModel.toJson()));
  }

  @override
  Future<User?> getCachedUser() async {
    final storedToken = _sharedPreferences.getString(_authTokenKey);
    final cachedUserStr = _sharedPreferences.getString(_userKey);
    if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(cachedUserStr) as Map<String, dynamic>;
        final userModel = UserModel.fromJson(
          userMap,
          token: storedToken != null && storedToken.isNotEmpty
              ? storedToken
              : null,
        );
        final tokenToUse =
            userModel.token.isNotEmpty
                ? userModel.token
                : (storedToken ?? '');
        if (tokenToUse.isNotEmpty) {
          _apiClient.setAuthToken(tokenToUse);
        }
        return userModel;
      } catch (_) {
        return null;
      }
    }
    if (storedToken != null && storedToken.isNotEmpty) {
      _apiClient.setAuthToken(storedToken);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (_) {
      // Ignore logout API failures to allow local logout to complete
    } finally {
      await _sharedPreferences.clear();
      _apiClient.clearAuthToken();
    }
  }

  @override
  Future<User> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Failed to fetch profile'));
      }

      final cachedUser = await getCachedUser();
      final token = cachedUser?.token ?? '';

      final userModel = UserModel.fromJson(data, token: token);
      await _cacheUser(userModel);
      return userModel;
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? companyName,
    String? profileImagePath,
  }) async {
    final Map<String, dynamic> map = {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    };

    if (companyName != null) {
      map['company_name'] = companyName;
    }

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      map['profile_image'] = await MultipartFile.fromFile(
        profileImagePath,
        filename: profileImagePath.split('/').last,
      );
    }

    final formData = FormData.fromMap(map);
    final response = await _apiClient.post(
      ApiConstants.updateProfile,
      data: formData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Profile update failed'));
      }

      final cachedUser = await getCachedUser();
      final token = cachedUser?.token ?? '';

      final userModel = UserModel.fromJson(data, token: token);
      await _cacheUser(userModel);
      return userModel;
    }

    throw ServerException('Invalid response format from server');
  }

  @override
  Future<User> removeProfileImage() async {
    final response = await _apiClient.post(ApiConstants.removeProfileImage);

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        throw AuthException(_extractErrorMessage(data, 'Failed to remove image'));
      }

      final cachedUser = await getCachedUser();
      final token = cachedUser?.token ?? '';

      final userModel = UserModel.fromJson(data, token: token);
      await _cacheUser(userModel);
      return userModel;
    }

    throw ServerException('Invalid response format from server');
  }
}
