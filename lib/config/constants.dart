class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const int safeThreshold = 300;
  static const int dangerThreshold = 500;
  static const int maxPPM = 1000;

  static const int readingInterval = 5;
  static const int dashboardRefreshInterval = 5;

  static const int pageSize = 20;
  static const int maxPageSize = 100;

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String selectedDeviceKey = 'selected_device';

  static const String notificationChannelId = 'gas_alerts';
  static const String notificationChannelName = 'Gas Leak Alerts';
  static const String notificationChannelDescription =
      'Notifications for gas leak detection alerts';

  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';

  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxLocationLength = 100;

  static const int chartDataPoints = 24;
  static const Duration chartInterval = Duration(hours: 1);
}
