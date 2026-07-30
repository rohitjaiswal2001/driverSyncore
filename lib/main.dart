import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        title: 'Syntracore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              // Pop all pushed screens to return to the root LoginPage
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return DriverMainShell(username: state.user.phoneNumber);
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
