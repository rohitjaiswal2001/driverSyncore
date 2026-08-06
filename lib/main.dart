import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/network/session_expired_handler.dart';
import 'core/theme/app_theme.dart';
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
        home: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              setState(() => _currentUser = state.user);
            } else if (state is AuthInitial) {
              setState(() => _currentUser = null);
            }
          },
          builder: (context, state) {
            final user = (state is AuthSuccess) ? state.user : _currentUser;
            if (user != null) {
              return DriverMainShell(username: user.phoneNumber);
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
