import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/forgot_password_form.dart';
import '../widgets/reset_password_form.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _resetFormKey = GlobalKey<ResetPasswordFormState>();

  String _email = '';
  bool _emailSent = false;
  String _sentMessage = '';

  Timer? _resendTimer;
  int _resendSeconds = 120;
  bool _canResend = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 120;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _sendResetCode(String email) {
    _email = email;
    context.read<AuthBloc>().add(ForgotPasswordSubmitted(email: email));
  }

  void _resendCode() {
    if (!_canResend) return;
    _resetFormKey.currentState?.clearOtp();
    context.read<AuthBloc>().add(ResendOtpRequested(email: _email));
  }

  void _verifyAndReset(String otp, String password, String confirmPassword) {
    context.read<AuthBloc>().add(
      ResetPasswordSubmitted(
        email: _email,
        otp: otp,
        password: password,
        passwordConfirmation: confirmPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordEmailSent) {
            setState(() {
              _emailSent = true;
              _sentMessage = state.message;
            });
            _startResendTimer();
          } else if (state is OtpResentSuccess) {
            TopSnackBar.show(
              context,
              message: state.message,
              backgroundColor: AppColors.accentGreen,
              icon: Icons.check_circle_outline,
            );
            _startResendTimer();
          } else if (state is PasswordResetSuccess) {
            TopSnackBar.show(
              context,
              message: state.message,
              backgroundColor: AppColors.accentGreen,
              icon: Icons.check_circle_outline,
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is AuthFailure) {
            TopSnackBar.show(
              context,
              message: state.errorMessage,
              backgroundColor: Colors.redAccent,
              icon: Icons.error_outline,
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: _emailSent
                  ? ResetPasswordForm(
                      key: _resetFormKey,
                      email: _email,
                      message: _sentMessage,
                      canResend: _canResend,
                      resendSeconds: _resendSeconds,
                      onResend: _resendCode,
                      onVerify: _verifyAndReset,
                    )
                  : ForgotPasswordForm(onSubmit: _sendResetCode),
            ),
          );
        },
      ),
    );
  }
}
