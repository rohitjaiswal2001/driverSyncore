import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../utils/active_order_store.dart';
import '../utils/document_downloader.dart';
import '../utils/recent_orders_store.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/login_with_otp_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/resend_otp_usecase.dart';
import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/domain/usecases/remove_profile_image_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/repositories/trips_repository.dart';
import '../../features/trips/domain/usecases/get_trip_details_usecase.dart';
import '../../features/trips/domain/usecases/update_trip_status_usecase.dart';
import '../../features/trips/domain/usecases/get_quotes_usecase.dart';
import '../../features/trips/domain/usecases/request_quote_usecase.dart';
import '../../features/trips/domain/usecases/accept_quote_usecase.dart';
import '../../features/trips/domain/usecases/get_quote_master_data_usecase.dart';
import '../../features/trips/domain/usecases/create_booking_quote_usecase.dart';
import '../../features/trips/domain/usecases/get_dashboard_data_usecase.dart';
import '../../features/trips/presentation/bloc/trips_bloc.dart';
import '../../features/trips/presentation/bloc/dashboard_bloc.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => RecentOrdersStore(sharedPreferences));
  sl.registerLazySingleton(() => ActiveOrderStore(sharedPreferences));
  // The app's one and only HTTP client - see ApiClient for every network
  // setting. Document downloads go through its external transport.
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => DocumentDownloader(sl()));

  // Features - Auth

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      loginWithOtpUseCase: sl(),
      registerUseCase: sl(),
      verifyOtpUseCase: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      getCachedUserUseCase: sl(),
      logoutUseCase: sl(),
      resendOtpUseCase: sl(),
      getProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      removeProfileImageUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithOtpUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ResendOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => RemoveProfileImageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));

  // Features - Trips
  // Bloc
  sl.registerFactory(
    () => TripsBloc(
      getTripDetailsUseCase: sl(),
      updateTripStatusUseCase: sl(),
      getQuotesUseCase: sl(),
      requestQuoteUseCase: sl(),
      acceptQuoteUseCase: sl(),
      getQuoteMasterDataUseCase: sl(),
      createBookingQuoteUseCase: sl(),
    ),
  );
  sl.registerFactory(() => DashboardBloc(getDashboardDataUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetTripDetailsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTripStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetQuotesUseCase(sl()));
  sl.registerLazySingleton(() => RequestQuoteUseCase(sl()));
  sl.registerLazySingleton(() => AcceptQuoteUseCase(sl()));
  sl.registerLazySingleton(() => GetQuoteMasterDataUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingQuoteUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardDataUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TripsRepository>(() => TripsRepositoryImpl(sl()));
}
