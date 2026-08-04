import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Hero card at the top of the driver profile.
///
/// Shows identity (avatar, name, company) plus contact details.
class DriverProfileHeader extends StatelessWidget {
  final String name;
  final String company;
  final String phone;
  final String? email;
  final String? profileImage;
  final bool isOnDuty;
  final String avatarHeroTag;

  /// Opens the full-screen photo viewer. Null when there is no photo to open.
  final VoidCallback? onAvatarTap;

  /// Opens the edit-profile flow (also used by the camera badge).
  final VoidCallback onEditProfile;

  const DriverProfileHeader({
    super.key,
    required this.name,
    required this.company,
    required this.phone,
    required this.onEditProfile,
    required this.isOnDuty,
    this.onAvatarTap,
    this.email,
    this.profileImage,
    this.avatarHeroTag = 'profile_avatar_hero',
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profileImage != null && profileImage!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(hasPhoto),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              // Quick access to the primary action on this screen.
              Semantics(
                button: true,
                label: 'Edit profile',
                child: Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onEditProfile,
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
          const SizedBox(height: 14),
          _ContactRow(icon: Icons.phone_rounded, value: phone),
          if (email != null && email!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ContactRow(icon: Icons.mail_outline_rounded, value: email!.trim()),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool hasPhoto) {
    final avatar = UserAvatar(
      name: name,
      imageUrl: profileImage,
      radius: 34,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
    );

    return Semantics(
      button: hasPhoto,
      label: hasPhoto ? 'View profile photo' : 'Profile photo',
      child: GestureDetector(
        onTap: hasPhoto ? onAvatarTap : onEditProfile,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Only the photo participates in the hero flight to the viewer.
            hasPhoto ? Hero(tag: avatarHeroTag, child: avatar) : avatar,
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.navy, width: 2),
                ),
                child: Icon(
                  hasPhoto ? Icons.zoom_in_rounded : Icons.photo_camera_rounded,
                  color: AppColors.navy,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
