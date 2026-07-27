import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  final DashboardData? previousData;

  const DashboardLoading({this.previousData});

  @override
  List<Object?> get props => [previousData];
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;

  const DashboardLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String errorMessage;
  final DashboardData? previousData;

  const DashboardError({required this.errorMessage, this.previousData});

  @override
  List<Object?> get props => [errorMessage, previousData];
}

class DashboardTokenExpired extends DashboardState {
  final String errorMessage;

  const DashboardTokenExpired({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
