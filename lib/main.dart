import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/network/session_expired_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/top_snack_bar.dart';
import 'features/auth/domain/entities/user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/trips/presentation/bloc/trips_bloc.dart';
import 'features/trips/presentation/bloc/dashboard_bloc.dart';
import 'features/trips/presentation/bloc/dashboard_event.dart';
import 'features/trips/presentation/pages/driver_main_shell.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _currentUser;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    di.sl<ApiClient>().onUnauthorized = (path) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        SessionExpiredHandler.showUnauthorizedDialog(context, path: path);
      }
    };
  }

  /// Discards every route pushed on top of the root route.
  ///
  /// The root route is the only widget that switches between the login page and
  /// the driver shell, so it must stay on the stack for the lifetime of the app.
  /// Replacing it (`pushAndRemoveUntil` with a `false` predicate) is what used
  /// to leave a re-login with nothing listening to the auth state, forcing an
  /// app restart. Popping back to it instead keeps the switch alive.
  void _resetToRootRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      final wasSignedOut = _currentUser == null;
      setState(() => _currentUser = state.user);
      // Profile fetches/updates also emit AuthSuccess, so only a transition out
      // of the signed-out state may clear routes the user is sitting on.
      if (wasSignedOut) _resetToRootRoute();
    } else if (state is AuthLoggedOut) {
      // Drop any toast left over from the session that just ended.
      TopSnackBar.dismiss();
      setState(() => _currentUser = null);
      _resetToRootRoute();
    } else if (state is AuthInitial && _currentUser != null) {
      // Session dropped without an explicit logout (e.g. cache check failed).
      setState(() => _currentUser = null);
      _resetToRootRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<TripsBloc>(create: (_) => di.sl<TripsBloc>()),
        BlocProvider<DashboardBloc>(
          create: (_) => di.sl<DashboardBloc>()..add(const LoadDashboardData()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'GlobeLink Driver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Sits above the Navigator, so the logout spinner covers pushed pages
        // (profile, tracking) as well as the root route.
        builder: (context, child) {
          return BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) =>
                previous is AuthLoggingOut || current is AuthLoggingOut,
            builder: (context, state) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ?child,
                  if (state is AuthLoggingOut) const _LogoutOverlay(),
                ],
              );
            },
          );
        },
        home: BlocConsumer<AuthBloc, AuthState>(
          listener: _onAuthStateChanged,
          builder: (context, state) {
            final user = (state is AuthSuccess) ? state.user : _currentUser;

            return (user != null)
                ? DriverMainShell(username: user.phoneNumber)
                : const LoginPage();
          },
        ),
      ),
    );
  }
}

/// Blocking spinner shown while the logout request is in flight. The tinted
/// [Material] also swallows taps aimed at the page underneath.
class _LogoutOverlay extends StatelessWidget {
  const _LogoutOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Logging out...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
