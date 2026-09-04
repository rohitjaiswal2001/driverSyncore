class ApiConstants {
  static const String baseUrl =
      // 'https://perfectwebservices.com/staging/syntracore-tool/public/api';
      'https://flc.syntra-core.com/api';

  /// Single centralized timeout for every network call in the app - connect,
  /// send and receive, plus the outer ceilings the blocs and pull-to-refresh
  /// handlers put around a request. Change this one value to retune how long
  /// the app waits on the backend anywhere.
  static const Duration apiTimeout = Duration(seconds: 20);

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

  /// Single centralized location ping interval for backend location updates.
  /// Modify this single value to change the tracking frequency for the whole app.
  static const Duration locationPingInterval = Duration(minutes: 5);

  /// How often an open shipment screen re-reads its detail, so a status change
  /// made elsewhere - dispatch marking a trip failed, say - shows up on its own
  /// instead of waiting for the driver to pull to refresh.
  static const Duration shipmentRefreshInterval = Duration(seconds: 60);
}
