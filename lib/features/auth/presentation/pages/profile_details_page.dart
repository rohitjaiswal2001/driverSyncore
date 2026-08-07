import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bloc_refresh.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_bloc_extensions.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user.dart';
import 'edit_profile_page.dart';
import 'fullscreen_image_viewer.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  User? _cachedUser;

  Future<void> _handleRefresh() {
    return handleRefresh(
      context,
      () => context.read<AuthBloc>().refreshProfile(),
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
          'Personal Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            _cachedUser = state.user;
          }
          final user =
              _cachedUser ?? (state is AuthSuccess ? state.user : null);

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final fullName = '${user.firstName} ${user.lastName ?? ""}';
          final hasImage =
              user.profileImage != null && user.profileImage!.isNotEmpty;

          // Initials for avatar fallback
          String initials = '';
          if (fullName.trim().isNotEmpty) {
            final parts = fullName.trim().split(' ');
            initials += parts[0][0].toUpperCase();
            if (parts.length > 1 && parts.last.isNotEmpty) {
              initials += parts.last[0][0].toUpperCase();
            }
          }
          if (initials.isEmpty) initials = 'D';

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Hero
                  GestureDetector(
                    onTap: hasImage
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
                    child: Hero(
                      tag: 'profile_avatar_hero',
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary.withAlpha(26),
                        backgroundImage: hasImage
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: !hasImage
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasImage)
                    const Text(
                      'Tap to view photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Details Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          label: 'First Name',
                          value: user.firstName,
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          label: 'Last Name',
                          value: user.lastName ?? '-',
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: user.email,
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: user.phone,
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildDetailRow(
                          icon: Icons.business_outlined,
                          label: 'Company Name',
                          value: user.companyName.isNotEmpty
                              ? user.companyName
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Edit Profile Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMedium, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
