import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

import 'package:flutter/gestures.dart';
import 'otp_verification_page.dart';
import 'legal_document_page.dart';
import '../../../../core/widgets/top_snack_bar.dart';

class RegisterPage extends StatefulWidget {
  final String? initialRole;

  const RegisterPage({super.key, this.initialRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ValueNotifier<bool> _agreeToTerms = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isConfirmPasswordVisible = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const RoleChanged('Driver'));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _agreeToTerms.dispose();
    _isPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms.value) {
        TopSnackBar.show(
          context,
          message: 'You must agree to the Terms of Service & Privacy Policy',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline,
        );
        return;
      }

      context.read<AuthBloc>().add(
        RegisterSubmitted(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: 'driver',
          companyName: _companyController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        const themeColor = AppColors.primary;

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
              'Register as Driver',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(
            //       Icons.notifications_none,
            //       color: AppColors.textDark,
            //     ),
            //     onPressed: () {},
            //   ),
            //   const SizedBox(width: 8),
            // ],
          ),
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthLoading) {
                _isLoading.value = true;
              } else {
                _isLoading.value = false;
              }

              if (state is OtpVerificationRequired) {
                TopSnackBar.show(
                  context,
                  message: 'OTP sent to ${state.email}. Please verify.',
                  backgroundColor: AppColors.accentGreen,
                  icon: Icons.check_circle_outline,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OtpVerificationPage(email: state.email),
                  ),
                );
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 24.0,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create Your Account',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Fill in the details to get quickly started.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // First Name field
                                    const Text(
                                      'First Name',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _firstNameController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter your first name';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'First Name',
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: AppColors.textMedium,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Last Name field
                                    const Text(
                                      'Last Name',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _lastNameController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter your last name';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Last Name',
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: AppColors.textMedium,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Phone Number field
                                    const Text(
                                      'Phone Number (Optional)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return null;
                                        }
                                        if (val.trim().length < 10) {
                                          return 'Enter a valid phone number';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Phone Number (e.g. +919876543210)',
                                        prefixIcon: Icon(
                                          Icons.phone_outlined,
                                          color: AppColors.textMedium,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Company Name field
                                    const Text(
                                      'Company Name (Optional)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _companyController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      validator: null,
                                      decoration: const InputDecoration(
                                        hintText: 'Company Name',
                                        prefixIcon: Icon(
                                          Icons.business_outlined,
                                          color: AppColors.textMedium,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Email Address field
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
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Enter email address';
                                        }
                                        if (!val.contains('@') ||
                                            !val.contains('.')) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your email address',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: AppColors.textMedium,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Password field
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _isPasswordVisible,
                                      builder: (context, visible, _) {
                                        return TextFormField(
                                          controller: _passwordController,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          obscureText: !visible,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                          validator:
                                              Validators.validatePassword,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Create a strong password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppColors.textMedium,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                visible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: AppColors.textMedium,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _isPasswordVisible.value =
                                                    !visible;
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Confirm Password field
                                    const Text(
                                      'Confirm Password',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          _isConfirmPasswordVisible,
                                      builder: (context, visible, _) {
                                        return TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          obscureText: !visible,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return 'Confirm your password';
                                            }
                                            if (val !=
                                                _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Confirm your password',
                                            prefixIcon: const Icon(
                                              Icons.lock_reset,
                                              color: AppColors.textMedium,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                visible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: AppColors.textMedium,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _isConfirmPasswordVisible
                                                        .value =
                                                    !visible;
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Terms and Conditions checkbox
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: ValueListenableBuilder<bool>(
                                            valueListenable: _agreeToTerms,
                                            builder: (context, agree, _) {
                                              return Checkbox(
                                                value: agree,
                                                activeColor: themeColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                onChanged: (val) {
                                                  _agreeToTerms.value =
                                                      val ?? false;
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I agree to the ',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textMedium,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: const TextStyle(
                                                    color: AppColors.accentBlue,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      LegalDocumentPage.openTerms(
                                                        context,
                                                      );
                                                    },
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: const TextStyle(
                                                    color: AppColors.accentBlue,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      LegalDocumentPage.openPrivacy(
                                                        context,
                                                      );
                                                    },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    // Register Button
                                    ElevatedButton(
                                      onPressed: _submitRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: themeColor,
                                        minimumSize: const Size.fromHeight(54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Already have account link
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: RichText(
                                          text: const TextSpan(
                                            text: 'Already have an account? ',
                                            style: TextStyle(
                                              color: AppColors.textMedium,
                                              fontSize: 14,
                                            ),
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
                                  ],
                                ),
                              ),
                            ),
                            // Bottom semi-truck illustration
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: Image.asset(
                                  'assets/images/truck.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, loading, _) {
                    if (!loading) return const SizedBox.shrink();
                    return Container(
                      color: Colors.black.withAlpha(77),
                      child: Center(
                        child: CircularProgressIndicator(color: themeColor),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
