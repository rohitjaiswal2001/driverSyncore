import '../../domain/entities/dashboard_data.dart';

class DashboardModel extends DashboardData {
  const DashboardModel({
    required super.summary,
    required super.bookingOverview,
    required super.yearlyBookingOverview,
    required super.recentBookings,
    required super.recentQuotes,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return DashboardModel(
      summary: DashboardSummaryModel.fromJson(
        data['summary'] as Map<String, dynamic>? ?? {},
      ),
      bookingOverview: DashboardBookingOverviewModel.fromJson(
        data['booking_overview'] as Map<String, dynamic>? ?? {},
      ),
      yearlyBookingOverview: DashboardYearlyBookingOverviewModel.fromJson(
        data['yearly_booking_overview'] as Map<String, dynamic>? ?? {},
      ),
      recentBookings: (data['recent_bookings'] as List? ?? [])
          .map((item) => DashboardRecentBookingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentQuotes: (data['recent_quotes'] as List? ?? [])
          .map((item) => DashboardRecentQuoteModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.totalBookings,
    required super.pending,
    required super.approved,
    required super.ongoing,
    required super.rejected,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalBookings: json['total_bookings'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      ongoing: json['ongoing'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}

class DashboardBookingOverviewModel extends DashboardBookingOverview {
  const DashboardBookingOverviewModel({
    required super.month,
    required super.year,
    required super.chartData,
    required super.legend,
  });

  factory DashboardBookingOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardBookingOverviewModel(
      month: json['month'] as int? ?? 0,
      year: json['year'] as int? ?? 0,
      chartData: (json['chart_data'] as List? ?? [])
          .map((item) => DashboardChartDataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      legend: DashboardBookingOverviewLegendModel.fromJson(
        json['legend'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DashboardChartDataPointModel extends DashboardChartDataPoint {
  const DashboardChartDataPointModel({
    required super.date,
    required super.total,
  });

  factory DashboardChartDataPointModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'];
    final total = rawTotal != null 
        ? (double.tryParse(rawTotal.toString())?.toInt() ?? int.tryParse(rawTotal.toString()) ?? 0) 
        : 0;
    return DashboardChartDataPointModel(
      date: json['date'] as String? ?? '',
      total: total,
    );
  }
}

class DashboardBookingOverviewLegendModel extends DashboardBookingOverviewLegend {
  const DashboardBookingOverviewLegendModel({
    required super.total,
    required super.approved,
    required super.pending,
    required super.rejected,
  });

  factory DashboardBookingOverviewLegendModel.fromJson(Map<String, dynamic> json) {
    return DashboardBookingOverviewLegendModel(
      total: json['total'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}

class DashboardYearlyBookingOverviewModel extends DashboardYearlyBookingOverview {
  const DashboardYearlyBookingOverviewModel({
    required super.year,
    required super.chartData,
  });

  factory DashboardYearlyBookingOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardYearlyBookingOverviewModel(
      year: json['year'] as int? ?? 0,
      chartData: (json['chart_data'] as List? ?? [])
          .map((item) => DashboardYearlyChartDataPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardYearlyChartDataPointModel extends DashboardYearlyChartDataPoint {
  const DashboardYearlyChartDataPointModel({
    required super.month,
    required super.total,
  });

  factory DashboardYearlyChartDataPointModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'];
    final total = rawTotal != null 
        ? (double.tryParse(rawTotal.toString())?.toInt() ?? int.tryParse(rawTotal.toString()) ?? 0) 
        : 0;
    return DashboardYearlyChartDataPointModel(
      month: json['month'] as String? ?? '',
      total: total,
    );
  }
}

class DashboardRecentBookingModel extends DashboardRecentBooking {
  const DashboardRecentBookingModel({
    required super.bookingId,
    required super.orderId,
    required super.customer,
    required super.date,
    required super.status,
  });

  factory DashboardRecentBookingModel.fromJson(Map<String, dynamic> json) {
    return DashboardRecentBookingModel(
      bookingId: json['booking_id'] as int? ?? 0,
      orderId: json['order_id']?.toString(),
      customer: json['customer'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class DashboardRecentQuoteModel extends DashboardRecentQuote {
  const DashboardRecentQuoteModel({
    required super.bookingId,
    required super.customer,
    required super.amount,
    required super.status,
  });

  factory DashboardRecentQuoteModel.fromJson(Map<String, dynamic> json) {
    return DashboardRecentQuoteModel(
      bookingId: json['booking_id'] as int? ?? 0,
      customer: json['customer'] as String? ?? '',
      amount: json['amount']?.toString() ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
