import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/api_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/top_snack_bar.dart';

/// Pull-to-refresh plumbing for every bloc-driven page, in one place.
extension BlocRefresh<E, S> on Bloc<E, S> {
  /// Dispatches [event] and completes once the bloc settles on a state
  /// [isTerminal] accepts.
  ///
  /// This is what keeps a RefreshIndicator spinning for the real duration of
  /// the request instead of snapping back the moment the event is queued.
  /// Times out after [timeout] - the app-wide [ApiConstants.apiTimeout] unless
  /// a caller says otherwise - and throws TimeoutException when it does, which
  /// [handleRefresh] turns into the standard message.
  Future<void> refreshWith(
    E event, {
    required bool Function(S state) isTerminal,
    Duration timeout = ApiConstants.apiTimeout,
  }) async {
    final completer = Completer<void>();
    final subscription = stream.listen((state) {
      if (isTerminal(state) && !completer.isCompleted) {
        completer.complete();
      }
    });

    add(event);

    try {
      await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }
}

/// Wraps a pull-to-refresh [action] so a backend that never answers reads the
/// same way on every screen instead of the spinner just vanishing.
///
/// Only the timeout is handled here: real failures arrive as bloc states
/// (AuthFailure, TripsError, ...) and stay each page's own business.
Future<void> handleRefresh(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on TimeoutException {
    if (!context.mounted) return;
    TopSnackBar.show(
      context,
      message: 'Taking longer than usual. Check your connection.',
      backgroundColor: AppColors.accentOrange,
      icon: Icons.wifi_off_rounded,
    );
  }
}
