import 'dart:async';

import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

extension AuthBlocRefresh on AuthBloc {
  /// Requests fresh profile details and completes once the bloc settles on a
  /// success or failure state.
  ///
  /// Lets pull-to-refresh keep its spinner up for the real duration of the
  /// request instead of snapping back immediately. Throws [TimeoutException]
  /// if no terminal state arrives within [timeout].
  Future<void> refreshProfile({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final completer = Completer<void>();
    final subscription = stream.listen((state) {
      if (state is AuthSuccess || state is AuthFailure) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    add(const GetProfileDetails());

    try {
      await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }
}
