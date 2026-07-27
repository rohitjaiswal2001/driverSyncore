import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import '../../domain/entities/dashboard_data.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  DashboardBloc({
    required this.getDashboardDataUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    DashboardData? previousData;
    if (currentState is DashboardLoaded) {
      previousData = currentState.data;
    } else if (currentState is DashboardLoading) {
      previousData = currentState.previousData;
    } else if (currentState is DashboardError) {
      previousData = currentState.previousData;
    }

    emit(DashboardLoading(previousData: previousData));
    try {
      final dashboardData = await getDashboardDataUseCase();
      emit(DashboardLoaded(data: dashboardData));
    } catch (e) {
      if (e is AuthException ||
          e.toString().toLowerCase().contains('unauthorized')) {
        emit(
          DashboardTokenExpired(
            errorMessage: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      } else {
        emit(
          DashboardError(
            errorMessage: e.toString().replaceAll('Exception: ', ''),
            previousData: previousData,
          ),
        );
      }
    }
  }
}
