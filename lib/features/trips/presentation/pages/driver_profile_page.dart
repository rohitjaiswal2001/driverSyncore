import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/profile_details_page.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../../../auth/presentation/pages/fullscreen_image_viewer.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/driver_profile_header.dart';
import '../widgets/profile_setting_tile.dart';

class DriverProfilePage extends StatefulWidget {
  final String username;

  const DriverProfilePage({super.key, required this.username});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final bool _isOnDuty = true;
  User? _cachedUser;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch fresh profile details on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const GetProfileDetails());
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    final authBloc = context.read<AuthBloc>();
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = authBloc.stream.listen((state) {
      if (state is AuthSuccess || state is AuthFailure) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription.cancel();
      }
    });

    authBloc.add(const GetProfileDetails());

    try {
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          subscription.cancel();
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Warning Icon
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Message
              const Text(
                'Are you sure you want to log out? You will need to verify your credentials to log back in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ctx.read<AuthBloc>().add(const LogoutRequested());
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textDark,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            debugPrint('BLOC AUTH FAILURE DETECTED: ${state.errorMessage}');
            TopSnackBar.show(
              context,
              message: state.errorMessage,
              backgroundColor: Colors.redAccent,
              icon: Icons.error_outline,
            );
          }
        },
        builder: (context, state) {
          if (state is AuthSuccess) {
            _cachedUser = state.user;
          }
          final user = _cachedUser;
          final isLoading = state is AuthLoading && !_isRefreshing;

          return LoadingOverlay(
            isLoading: isLoading,
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    DriverProfileHeader(
                      name: user != null
                          ? '${user.firstName} ${user.lastName ?? ""}'
                          : 'Driver Name',
                      username: user?.phone ?? widget.username,
                      profileImage: user?.profileImage,
                      isOnDuty: _isOnDuty,
                      onAvatarTap:
                          (user?.profileImage != null &&
                              user!.profileImage!.isNotEmpty)
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullscreenImageViewer(
                                  imageUrl: user.profileImage!,
                                  heroTag: 'profile_avatar_hero',
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // 3. MANAGEMENT SECTION
                    _buildSectionHeader('MANAGEMENT'),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ProfileSettingTile(
                            icon: Icons.person_outline,
                            title: 'Personal Details',
                            subtitle: user != null
                                ? '${user.firstName} ${user.lastName ?? ""}, ${user.phone}'
                                : 'Name, License, Phone',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileDetailsPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ProfileSettingTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Change your profile information',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ProfileSettingTile(
                            icon: Icons.local_shipping_outlined,
                            title: 'Vehicle Details',
                            subtitle: 'MH01AB1234 - 14 Ft Truck',
                            onTap: () {},
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ProfileSettingTile(
                            icon: Icons.assignment_outlined,
                            title: 'Documents',
                            subtitle: 'KYC, Permits, Insurance',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. SYSTEM SECTION
                    _buildSectionHeader('SYSTEM'),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ProfileSettingTile(
                            icon: Icons.shield_outlined,
                            title: 'Security',
                            subtitle: 'Change PIN, Permissions',
                            onTap: () {},
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ProfileSettingTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'FAQs, Contact Admin',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 5. Action Buttons
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Export Profile Data',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE2E2),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showLogoutDialog(context),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMedium,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
