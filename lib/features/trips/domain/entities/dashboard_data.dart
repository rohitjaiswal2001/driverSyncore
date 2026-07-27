import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final DashboardSummary summary;
  final DashboardBookingOverview bookingOverview;
  final DashboardYearlyBookingOverview yearlyBookingOverview;
  final List<DashboardRecentBooking> recentBookings;
  final List<DashboardRecentQuote> recentQuotes;

  const DashboardData({
    required this.summary,
    required this.bookingOverview,
    required this.yearlyBookingOverview,
    required this.recentBookings,
    required this.recentQuotes,
  });

  @override
  List<Object?> get props => [
        summary,
        bookingOverview,
        yearlyBookingOverview,
        recentBookings,
        recentQuotes,
      ];
}

class DashboardSummary extends Equatable {
  final int totalBookings;
  final int pending;
  final int approved;
  final int ongoing;
  final int rejected;

  const DashboardSummary({
    required this.totalBookings,
    required this.pending,
    required this.approved,
    required this.ongoing,
    required this.rejected,
  });

  @override
  List<Object?> get props => [totalBookings, pending, approved, ongoing, rejected];
}

class DashboardBookingOverview extends Equatable {
  final int month;
  final int year;
  final List<DashboardChartDataPoint> chartData;
  final DashboardBookingOverviewLegend legend;

  const DashboardBookingOverview({
    required this.month,
    required this.year,
    required this.chartData,
    required this.legend,
  });

  @override
  List<Object?> get props => [month, year, chartData, legend];
}

class DashboardChartDataPoint extends Equatable {
  final String date;
  final int total;

  const DashboardChartDataPoint({
    required this.date,
    required this.total,
  });

  @override
  List<Object?> get props => [date, total];
}

class DashboardBookingOverviewLegend extends Equatable {
  final int total;
  final int approved;
  final int pending;
  final int rejected;

  const DashboardBookingOverviewLegend({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  @override
  List<Object?> get props => [total, approved, pending, rejected];
}

class DashboardYearlyBookingOverview extends Equatable {
  final int year;
  final List<DashboardYearlyChartDataPoint> chartData;

  const DashboardYearlyBookingOverview({
    required this.year,
    required this.chartData,
  });

  @override
  List<Object?> get props => [year, chartData];
}

class DashboardYearlyChartDataPoint extends Equatable {
  final String month;
  final int total;

  const DashboardYearlyChartDataPoint({
    required this.month,
    required this.total,
  });

  @override
  List<Object?> get props => [month, total];
}

class DashboardRecentBooking extends Equatable {
  final int bookingId;
  final String? orderId;
  final String customer;
  final String date;
  final String status;

  const DashboardRecentBooking({
    required this.bookingId,
    required this.orderId,
    required this.customer,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, orderId, customer, date, status];
}

class DashboardRecentQuote extends Equatable {
  final int bookingId;
  final String customer;
  final String amount;
  final String status;

  const DashboardRecentQuote({
    required this.bookingId,
    required this.customer,
    required this.amount,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, customer, amount, status];
}
