import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_features_bar.dart';
import '../widgets/login_header.dart';
import '../widgets/password_input_field.dart';
import '../../../trips/presentation/pages/driver_main_shell.dart';
import 'register_page.dart';
import 'otp_verification_page.dart';
import 'forgot_password_page.dart';
import '../../../../core/widgets/top_snack_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _userInitiatedLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _userInitiatedLogin = true;
      });
      final email = _emailController.text.trim();

      context.read<AuthBloc>().add(
        LoginSubmitted(email: email, password: _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            if (_userInitiatedLogin) {
              TopSnackBar.show(
                context,
                message: 'Welcome! Logged in as ${state.user.role}',
                backgroundColor: AppColors.accentGreen,
                icon: Icons.check_circle_outline,
              );
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DriverMainShell(username: state.user.phoneNumber),
              ),
            );
          } else if (state is AuthFailure) {
            setState(() {
              _userInitiatedLogin = false;
            });
            TopSnackBar.show(
              context,
              message: state.errorMessage,
              backgroundColor: Colors.redAccent,
              icon: Icons.error_outline,
            );
            if (state.errorMessage.toLowerCase().contains(
              'verify your email',
            )) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OtpVerificationPage(email: _emailController.text.trim()),
                ),
              );
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SafeArea(
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
                              // Top & Middle Form Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 16.0,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const LoginHeader(),
                                      const SizedBox(height: 28),

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
                                        textInputAction: TextInputAction.next,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                        validator: Validators.validateEmail,
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

                                      // Password Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Password',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ForgotPasswordPage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      PasswordInputField(
                                        controller: _passwordController,
                                        onFieldSubmitted: _submitLogin,
                                      ),
                                      const SizedBox(height: 24),

                                      // Submit Form Button
                                      ElevatedButton(
                                        onPressed: _submitLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          minimumSize: const Size.fromHeight(
                                            54,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.login_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Login',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const RegisterPage(
                                                      initialRole: 'Driver',
                                                    ),
                                              ),
                                            );
                                          },
                                          child: RichText(
                                            text: const TextSpan(
                                              text: "Don't have an account? ",
                                              style: TextStyle(
                                                color: AppColors.textMedium,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Register Now',
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
                              // Truck Image Illustration
                              Container(
                                width: double.infinity,

                                margin: const EdgeInsets.symmetric(vertical: 8),

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Image.asset(
                                    'assets/images/truck.png',
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                              // Bottom Features Sheet
                              const LoginFeaturesBar(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (state is AuthLoading)
                    Container(
                      color: Colors.black.withAlpha(77),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
