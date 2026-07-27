import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/truck_illustration.dart';

/// Email-entry step of the forgot-password flow.
/// Owns its own form state and only reports the validated email upward.
class ForgotPasswordForm extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const ForgotPasswordForm({super.key, required this.onSubmit});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Forgot your password?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No worries! Enter the email address linked to your account and we\'ll send you a code to reset your password.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter your email address';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Enter your registered email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.textMedium,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Send Reset Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: const TextSpan(
                  text: 'Remember your password? ',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const TruckIllustration(),
        ],
      ),
    );
  }
}
