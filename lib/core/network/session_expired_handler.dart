import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../di/injection_container.dart' as di;
import '../theme/app_colors.dart';
import '../utils/active_order_store.dart';
import '../utils/recent_orders_store.dart';
import 'api_client.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class SessionExpiredHandler {
  static bool _isDialogShowing = false;

  static const List<String> whitelistedEndpoints = [
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.forgotPassword,
    ApiConstants.resetPassword,
    ApiConstants.resendOtp,
    ApiConstants.verifyOtp,
    ApiConstants.logout,
  ];

  static bool isWhitelisted(String? path) {
    if (path == null || path.isEmpty) return false;
    final lowerPath = path.toLowerCase();
    return whitelistedEndpoints.any(
      (endpoint) =>
          lowerPath.endsWith(endpoint.toLowerCase()) ||
          lowerPath.contains(endpoint.toLowerCase()),
    );
  }

  static Future<void> showUnauthorizedDialog(
    BuildContext context, {
    String? path,
  }) async {
    if (isWhitelisted(path)) return;
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.lock_clock_outlined,
            size: 52,
            color: AppColors.accentOrange,
          ),
          title: const Text(
            'Session Expired',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Your login session has expired or is no longer valid. Please log in again to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(
            bottom: 20,
            left: 20,
            right: 20,
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;

                // Clear SharedPreferences & network headers
                try {
                  final prefs = di.sl<SharedPreferences>();
                  await prefs.clear();
                } catch (_) {}

                try {
                  di.sl<ApiClient>().clearAuthToken();
                } catch (_) {}

                try {
                  await di.sl<ActiveOrderStore>().clear();
                } catch (_) {}

                try {
                  await di.sl<RecentOrdersStore>().clear();
                } catch (_) {}

                if (context.mounted) {
                  context.read<AuthBloc>().add(const LogoutRequested());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Re-login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );

    _isDialogShowing = false;
  }
}
