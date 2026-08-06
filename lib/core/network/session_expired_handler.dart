import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/api_constants.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

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
    final parsedPath = Uri.tryParse(path)?.path ?? path;
    final lowerPath = parsedPath.toLowerCase();
    return whitelistedEndpoints.any(
      (endpoint) =>
          lowerPath.endsWith(endpoint.toLowerCase()) ||
          lowerPath.contains(endpoint.toLowerCase()),
    );
  }

  /// Reads the bloc without throwing when it is somehow out of scope, so a
  /// lookup failure can never take the whole handler down.
  static AuthBloc? _readAuthBloc(BuildContext context) {
    try {
      return context.read<AuthBloc>();
    } catch (error) {
      debugPrint('SessionExpiredHandler could not reach AuthBloc: $error');
      return null;
    }
  }

  /// True when there is no session left to expire - already logged out, or a
  /// logout is in flight. A late 401 from an in-flight request would otherwise
  /// pop this dialog on top of the login screen.
  static bool _hasNoSession(AuthState state) =>
      state is AuthInitial || state is AuthLoggedOut || state is AuthLoggingOut;

  static Future<void> showUnauthorizedDialog(
    BuildContext context, {
    String? path,
  }) async {
    if (isWhitelisted(path)) return;
    if (_isDialogShowing) return;

    final authBloc = _readAuthBloc(context);
    if (authBloc == null || _hasNoSession(authBloc.state)) return;
    if (!context.mounted) return;

    _isDialogShowing = true;
    try {
      await _showDialog(context, authBloc);
    } catch (error) {
      // If the dialog cannot be shown, the session is still dead - sign out
      // anyway rather than leaving the driver in an app that can no longer
      // talk to the server.
      debugPrint('Session-expired dialog failed to show: $error');
      authBloc.add(const LogoutRequested());
    } finally {
      // Reset in a finally: leaving this stuck at true would silently suppress
      // every future session-expired dialog for the rest of the app's life.
      _isDialogShowing = false;
    }
  }

  static Future<void> _showDialog(BuildContext context, AuthBloc authBloc) {
    return showDialog<void>(
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
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Route through the same logout flow as the profile/dashboard
                // buttons: spinner, logout call, then the session (prefs, auth
                // header, stored order IDs) is cleared and the app returns to
                // the login page. Clearing the token here first would strip the
                // Authorization header the logout call still needs.
                //
                // The bloc was captured before the dialog opened, so this works
                // even though `context` may be gone by the time it is tapped.
                authBloc.add(const LogoutRequested());
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
  }
}
