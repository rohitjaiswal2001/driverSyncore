import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_info_sheet.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc_extensions.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../../../auth/presentation/pages/fullscreen_image_viewer.dart';
import '../../../auth/presentation/pages/profile_details_page.dart';
import '../widgets/driver_profile_header.dart';
import '../widgets/profile_setting_tile.dart';

class DriverProfilePage extends StatefulWidget {
  final String username;

  const DriverProfilePage({super.key, required this.username});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  static const String _avatarHeroTag = 'profile_avatar_hero';

  final bool _isOnDuty = true;

  User? _cachedUser;
  String? _loadError;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Seed from whatever the bloc already holds so the page renders instantly,
    // then fetch in the background to pick up server-side changes.
    final currentState = context.read<AuthBloc>().state;
    if (currentState is AuthSuccess) {
      _cachedUser = currentState.user;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const GetProfileDetails());
      }
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await context.read<AuthBloc>().refreshProfile();
    } on TimeoutException {
      if (mounted) {
        TopSnackBar.show(
          context,
          message: 'Taking longer than usual. Check your connection.',
          backgroundColor: AppColors.accentOrange,
          icon: Icons.wifi_off_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      setState(() {
        _cachedUser = state.user;
        _loadError = null;
      });
    } else if (state is AuthFailure) {
      setState(() => _loadError = state.errorMessage);

      // Only surface a toast when there is already content on screen; the
      // empty state renders the same error inline with a retry button. The
      // route check stops a failure raised by a page pushed on top of this one
      // (edit profile, for instance) from showing the toast twice.
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (_cachedUser != null && isCurrentRoute) {
        TopSnackBar.show(
          context,
          message: state.errorMessage,
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showAppConfirmDialog(
      context,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message:
          'You will need to sign in again to view your trips and update '
          'shipment status.',
      confirmLabel: 'Log out',
      accentColor: AppColors.danger,
      accentBackground: AppColors.dangerBg,
    );

    if (shouldLogout && mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  void _openPhoto(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrl: imageUrl,
          heroTag: _avatarHeroTag,
        ),
      ),
    );
  }

  void _openPage(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showComingSoon({
    required IconData icon,
    required String title,
    required String message,
  }) {
    HapticFeedback.selectionClick();
    showAppInfoSheet(
      context,
      icon: icon,
      title: title,
      message: message,
      accentColor: AppColors.accentOrange,
    );
  }

  Future<void> _launch(Uri uri, String failureMessage) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      TopSnackBar.show(
        context,
        message: failureMessage,
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
      );
    }
  }

  void _showSupport() {
    HapticFeedback.selectionClick();

    final actions = <AppSheetAction>[
      if (AppInfo.hasSupportPhone)
        AppSheetAction(
          icon: Icons.phone_rounded,
          label: 'Call support',
          value: AppInfo.supportPhone,
          color: AppColors.accentGreen,
          onTap: () => _launch(
            Uri(scheme: 'tel', path: AppInfo.supportPhone),
            'No phone app available on this device.',
          ),
        ),
      if (AppInfo.hasSupportEmail)
        AppSheetAction(
          icon: Icons.mail_outline_rounded,
          label: 'Email support',
          value: AppInfo.supportEmail,
          color: AppColors.accentBlue,
          onTap: () => _launch(
            Uri(scheme: 'mailto', path: AppInfo.supportEmail),
            'No mail app available on this device.',
          ),
        ),
    ];

    showAppInfoSheet(
      context,
      icon: Icons.support_agent_rounded,
      title: 'Help & Support',
      message: AppInfo.hasSupportContact
          ? 'Reach the fleet desk for trip, document or account issues.'
          : 'In-app support is on the way. For now, contact your fleet '
                'manager directly for trip or account issues.',
      accentColor: AppInfo.hasSupportContact
          ? AppColors.primary
          : AppColors.accentOrange,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _onAuthStateChanged,
        builder: (context, state) {
          final user = _cachedUser;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: user != null
                ? _buildContent(user)
                : (_loadError != null
                      ? _buildErrorState(_loadError!)
                      : _buildSkeleton()),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // States
  // ---------------------------------------------------------------------------

  Widget _buildContent(User user) {
    final fullName = '${user.firstName} ${user.lastName ?? ''}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : widget.username;
    final phone = user.phone.trim().isNotEmpty ? user.phone : widget.username;
    final company = user.companyName.trim().isNotEmpty
        ? user.companyName.trim()
        : user.role.toUpperCase();
    final hasPhoto =
        user.profileImage != null && user.profileImage!.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        DriverProfileHeader(
          name: displayName,
          company: company,
          phone: phone,
          email: user.email,
          profileImage: user.profileImage,
          isOnDuty: _isOnDuty,
          isVerified: user.isVerified,
          avatarHeroTag: _avatarHeroTag,
          onAvatarTap: hasPhoto
              ? () => _openPhoto(user.profileImage!.trim())
              : null,
          onEditProfile: () => _openPage(const EditProfilePage()),
        ),
        const SizedBox(height: 26),

        _sectionHeader('ACCOUNT'),
        const SizedBox(height: 10),
        _group([
          ProfileSettingTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal Details',
            subtitle: '$displayName · $phone',
            accentColor: AppColors.primary,
            onTap: () => _openPage(const ProfileDetailsPage()),
          ),
          ProfileSettingTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update your name, photo and contact details',
            accentColor: AppColors.accentBlue,
            onTap: () => _openPage(const EditProfilePage()),
          ),
          ProfileSettingTile(
            icon: Icons.assignment_outlined,
            title: 'Documents',
            subtitle: 'KYC, permits and insurance',
            accentColor: AppColors.accentPurple,
            badge: 'SOON',
            badgeColor: AppColors.accentOrange,
            onTap: () => _showComingSoon(
              icon: Icons.assignment_outlined,
              title: 'Documents',
              message:
                  'Uploading and tracking KYC, permits and insurance from the '
                  'app is coming in a future update.',
            ),
          ),
        ]),
        const SizedBox(height: 24),

        _sectionHeader('SUPPORT & SECURITY'),
        const SizedBox(height: 10),
        _group([
          ProfileSettingTile(
            icon: Icons.shield_outlined,
            title: 'Security',
            subtitle: 'PIN, permissions and device access',
            accentColor: AppColors.accentGreen,
            badge: 'SOON',
            badgeColor: AppColors.accentOrange,
            onTap: () => _showComingSoon(
              icon: Icons.shield_outlined,
              title: 'Security',
              message:
                  'App PIN and device permission controls are coming in a '
                  'future update.',
            ),
          ),
          ProfileSettingTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Reach the fleet desk',
            accentColor: AppColors.accentOrange,
            onTap: _showSupport,
          ),
        ]),
        const SizedBox(height: 28),

        _buildLogoutButton(),
        const SizedBox(height: 20),

        Center(
          child: Column(
            children: [
              Text(
                AppInfo.appName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Version ${AppInfo.version}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.dangerTint,
          foregroundColor: AppColors.danger,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text(
          'Log out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SkeletonBox(
          height: 196,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        const SizedBox(height: 26),
        const SkeletonBox(width: 90, height: 12),
        const SizedBox(height: 10),
        _skeletonGroup(3),
        const SizedBox(height: 24),
        const SkeletonBox(width: 140, height: 12),
        const SizedBox(height: 10),
        _skeletonGroup(2),
        const SizedBox(height: 28),
        const SkeletonBox(
          height: 54,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ],
    );
  }

  Widget _skeletonGroup(int rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 72, color: AppColors.divider),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SkeletonBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(Radius.circular(13)),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 13),
                        SizedBox(height: 8),
                        SkeletonBox(width: 180, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.danger,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Couldn't load your profile",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  width: 190,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _isRefreshing ? 'Retrying…' : 'Try again',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _confirmLogout,
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMedium,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Wraps [tiles] in a rounded card, inserting text-aligned dividers between
  /// them so groups read as a single surface.
  Widget _group(List<Widget> tiles) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 72, color: AppColors.divider),
            tiles[i],
          ],
        ],
      ),
    );
  }
}
