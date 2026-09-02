import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_otp_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/get_cached_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/remove_profile_image_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// This app ships to drivers only, so the role the API is told about is a
  /// constant. It must never be read back off the signed-in session: the
  /// login/profile payload does not always carry a `role`, and the empty
  /// string it parses to used to survive logout and get sent as the role on
  /// the next login attempt - which the API rejects with a 422.
  static const String _driverRole = 'Driver';

  final LoginUseCase loginUseCase;
  final LoginWithOtpUseCase loginWithOtpUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final GetCachedUserUseCase getCachedUserUseCase;
  final LogoutUseCase logoutUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final RemoveProfileImageUseCase removeProfileImageUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.loginWithOtpUseCase,
    required this.registerUseCase,
    required this.verifyOtpUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.getCachedUserUseCase,
    required this.logoutUseCase,
    required this.resendOtpUseCase,
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.removeProfileImageUseCase,
  }) : super(const AuthInitial(role: _driverRole)) {
    on<RoleChanged>(_onRoleChanged);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<LoginWithOtpSubmitted>(_onLoginWithOtpSubmitted);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<GetProfileDetails>(_onGetProfileDetails);
    on<UpdateProfileSubmitted>(_onUpdateProfileSubmitted);
    on<RemoveProfileImageSubmitted>(_onRemoveProfileImageSubmitted);
  }

  void _onRoleChanged(RoleChanged event, Emitter<AuthState> emit) {
    emit(AuthInitial(role: event.role));
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    const currentRole = _driverRole;
    emit(const AuthLoading(role: currentRole));
    try {
      final user = await loginUseCase(
        LoginParams(
          email: event.email,
          password: event.password,
          role: currentRole,
        ),
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      await registerUseCase(
        RegisterParams(
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email,
          phone: event.phone,
          role: event.role,
          companyName: event.companyName,
          password: event.password,
          passwordConfirmation: event.passwordConfirmation,
        ),
      );
      emit(OtpVerificationRequired(email: event.email, role: currentRole));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final user = await verifyOtpUseCase(
        VerifyOtpParams(email: event.email, otp: event.otp),
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoginWithOtpSubmitted(
    LoginWithOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    const currentRole = _driverRole;
    emit(const AuthLoading(role: currentRole));
    try {
      final user = await loginWithOtpUseCase(
        LoginWithOtpParams(phoneNumber: event.phoneNumber, role: currentRole),
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final message = await forgotPasswordUseCase(
        ForgotPasswordParams(email: event.email),
      );
      emit(
        ForgotPasswordEmailSent(
          email: event.email,
          message: message,
          role: currentRole,
        ),
      );
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final message = await resetPasswordUseCase(
        ResetPasswordParams(
          email: event.email,
          otp: event.otp,
          password: event.password,
          passwordConfirmation: event.passwordConfirmation,
        ),
      );
      emit(PasswordResetSuccess(message: message, role: currentRole));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await getCachedUserUseCase();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(const AuthInitial(role: _driverRole));
      }
    } catch (_) {
      emit(const AuthInitial(role: _driverRole));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Spinner up, 2. hit the API, 3. clear the local session (the use case
    // does this in its own `finally`), 4. spinner down and hand the app back to
    // the logged-out state — which is what drives the return to the login page.
    emit(const AuthLoggingOut(role: _driverRole));
    try {
      // Outer ceiling behind the repository's own network timeout, with a
      // small grace so the inner one always fires first. Whatever happens -
      // hung socket, plugin failure, anything - the spinner comes down and the
      // app returns to login.
      await logoutUseCase().timeout(
        ApiConstants.apiTimeout + const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Logout failed but proceeding with local logout: $e');
    } finally {
      emit(const AuthLoggedOut(role: _driverRole));
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final message = await resendOtpUseCase(
        ResendOtpParams(email: event.email),
      );
      emit(
        OtpResentSuccess(
          email: event.email,
          message: message,
          role: currentRole,
        ),
      );
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onGetProfileDetails(
    GetProfileDetails event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await getProfileUseCase();
      emit(AuthSuccess(user: user));
    } catch (_) {}
  }

  Future<void> _onUpdateProfileSubmitted(
    UpdateProfileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final user = await updateProfileUseCase(
        UpdateProfileParams(
          firstName: event.firstName,
          lastName: event.lastName,
          phone: event.phone,
          companyName: event.companyName,
          profileImagePath: event.profileImagePath,
        ),
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  Future<void> _onRemoveProfileImageSubmitted(
    RemoveProfileImageSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentRole = state.role;
    emit(AuthLoading(role: currentRole));
    try {
      final user = await removeProfileImageUseCase();
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(role: currentRole, errorMessage: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    if (error is DioException) {
      return 'Network connection issue. Please check your internet connection.';
    }
    debugPrint('Unexpected error in AuthBloc: $error');
    return 'An unexpected error occurred. Please try again.';
  }
}
