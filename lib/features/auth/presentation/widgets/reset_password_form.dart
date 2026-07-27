import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../core/widgets/truck_illustration.dart';
import '../../../../core/utils/validators.dart';
import 'otp_input_field.dart';
import 'password_input_field.dart';

/// OTP + new-password step of the forgot-password flow.
/// Owns its own OTP/password fields and only reports validated values
/// upward via [onVerify]. The parent still drives the resend countdown
/// since that timer needs to survive this widget being resent state.
class ResetPasswordForm extends StatefulWidget {
  final String email;
  final String message;
  final bool canResend;
  final int resendSeconds;
  final VoidCallback onResend;
  final void Function(String otp, String password, String confirmPassword)
  onVerify;

  const ResetPasswordForm({
    super.key,
    required this.email,
    required this.message,
    required this.canResend,
    required this.resendSeconds,
    required this.onResend,
    required this.onVerify,
  });

  @override
  State<ResetPasswordForm> createState() => ResetPasswordFormState();
}

class ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _otpFieldKey = GlobalKey<OtpInputFieldState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otpCode = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Called by the parent after it re-triggers the send-code API.
  void clearOtp() {
    _otpFieldKey.currentState?.clear();
    setState(() => _otpCode = '');
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleVerify() {
    if (_otpCode.length < 6) {
      TopSnackBar.show(
        context,
        message: 'Enter the 6-digit code sent to your email',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onVerify(
      _otpCode,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOtpComplete = _otpCode.length == 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.driverBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.message,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          widget.email,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // OTP entry — kept on top, above the new password fields.
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Enter 6-Digit Code',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OtpInputField(
          key: _otpFieldKey,
          length: 6,
          onChanged: (value) => setState(() => _otpCode = value),
        ),
        const SizedBox(height: 16),
        widget.canResend
            ? GestureDetector(
                onTap: widget.onResend,
                child: const Text(
                  "Didn't get the code? Resend",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBlue,
                  ),
                ),
              )
            : Text(
                'Resend code in ${_formatSeconds(widget.resendSeconds)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
        const SizedBox(height: 28),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              PasswordInputField(
                controller: _newPasswordController,
                hintText: 'Create a new password',
                prefixIcon: Icons.lock_outline,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              PasswordInputField(
                controller: _confirmPasswordController,
                hintText: 'Re-enter your new password',
                prefixIcon: Icons.lock_reset,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Confirm your new password';
                  }
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: isOtpComplete ? _handleVerify : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.border,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Verify & Reset Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text(
            'Back to Login',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const TruckIllustration(),
      ],
    );
  }
}
