import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/bloc_refresh.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

extension AuthBlocRefresh on AuthBloc {
  /// Requests fresh profile details and completes once the bloc settles on a
  /// success or failure state. Throws TimeoutException if neither arrives
  /// within [timeout].
  Future<void> refreshProfile({
    Duration timeout = ApiConstants.apiTimeout,
  }) {
    return refreshWith(
      const GetProfileDetails(),
      isTerminal: (state) => state is AuthSuccess || state is AuthFailure,
      timeout: timeout,
    );
  }
}
