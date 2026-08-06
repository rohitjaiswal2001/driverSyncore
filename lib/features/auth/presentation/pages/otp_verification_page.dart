import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../trips/presentation/pages/driver_main_shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/otp_input_field.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final GlobalKey<OtpInputFieldState> _otpKey = GlobalKey<OtpInputFieldState>();

  int _resendTimerSeconds = 120;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _resendTimerSeconds = 120;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() {
          _resendTimerSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitOtp([String? code]) {
    final otp = code ?? _otpKey.currentState?.code ?? '';
    if (otp.length == 6) {
      context.read<AuthBloc>().add(
        VerifyOtpSubmitted(email: widget.email, otp: otp),
      );
    } else {
      TopSnackBar.show(
        context,
        message: 'Please enter all 6 digits of the OTP',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void _resendOtp() {
    if (!_canResend) return;

    context.read<AuthBloc>().add(
      ResendOtpRequested(email: widget.email),
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
          'Verify OTP',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is AuthLoading;
          });

          if (state is AuthSuccess) {
            TopSnackBar.show(
              context,
              message: 'Account verified successfully! Welcome.',
              backgroundColor: AppColors.accentGreen,
              icon: Icons.check_circle_outline,
            );

            final route = MaterialPageRoute(
              builder: (context) => DriverMainShell(username: state.user.phoneNumber),
            );
            Navigator.pushAndRemoveUntil(context, route, (route) => false);
          } else if (state is OtpResentSuccess) {
            TopSnackBar.show(
              context,
              message: state.message,
              backgroundColor: AppColors.accentGreen,
              icon: Icons.check_circle_outline,
            );
            _startTimer();
          } else if (state is AuthFailure) {
            TopSnackBar.show(
              context,
              message: state.errorMessage,
              backgroundColor: Colors.redAccent,
              icon: Icons.error_outline,
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Enter Verification Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: 'We have sent a 6-digit OTP code to ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                        children: [
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    OtpInputField(
                      key: _otpKey,
                      length: 6,
                      onCompleted: (code) => _submitOtp(code),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Column(
                        children: [
                          if (!_canResend) ...[
                            Text(
                              'Resend code in ${_formatSeconds(_resendTimerSeconds)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _resendOtp,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: _submitOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Verify & Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withAlpha(77),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
