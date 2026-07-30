class ApiConstants {
  static const String baseUrl = 'https://perfectwebservices.com/staging/syntracore-tool/public/api';

  // Auth Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String logout = '/logout';
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String removeProfileImage = '/profile/remove-image';

  // Booking & Quote Endpoints
  static const String quoteData = '/quote-data';
  static const String bookingQuote = '/booking/quote';
  static const String confirmBooking = '/booking';
  static const String dashboard = '/dashboard';
  static const String shipmentDetails = '/shipment-details';

  // Live Tracking Endpoints
  /// Confirmed: GET returns the fixed list of tracking statuses
  /// (NOT_STARTED, SHIPMENT_START, ONGOING, SHIPPING_DONE, FAILED).
  static const String trackingStatuses = '/tracking-statuses';

  /// Live location & status update endpoint: POST /tracking/update
  static const String updateTrackingStatus = '/tracking/update';
}
