import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DriverProfileHeader extends StatelessWidget {
  final String name;
  final String username;
  final String? profileImage;
  final bool isOnDuty;
  final VoidCallback? onAvatarTap;

  const DriverProfileHeader({
    super.key,
    required this.name,
    required this.username,
    this.profileImage,
    required this.isOnDuty,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract initials
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.isNotEmpty) {
        initials += parts[0][0].toUpperCase();
        if (parts.length > 1 && parts.last.isNotEmpty) {
          initials += parts.last[0][0].toUpperCase();
        }
      }
    }
    if (initials.isEmpty) initials = 'D';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withAlpha(26),
                  backgroundImage: profileImage != null && profileImage!.isNotEmpty
                      ? NetworkImage(profileImage!)
                      : null,
                  child: profileImage == null || profileImage!.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                if (onAvatarTap != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Driver Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver ID: DRV-${username.isNotEmpty ? username : "88902"}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOnDuty
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOnDuty
                          ? const Color(0xFF059669)
                          : AppColors.textMedium,
                    ),
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
