import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../screens/devices/device_detail_screen.dart';
import '../screens/devices/add_device_screen.dart';
import '../screens/devices/device_settings_screen.dart';
import '../screens/alerts/alert_list_screen.dart';
import '../screens/alerts/alert_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String deviceList = '/devices';
  static const String deviceDetail = '/device-detail';
  static const String addDevice = '/add-device';
  static const String deviceSettings = '/device-settings';
  static const String alertList = '/alerts';
  static const String alertDetail = '/alert-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    verifyEmail: (context) => const VerifyEmailScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    dashboard: (context) => const DashboardScreen(),
    deviceList: (context) => const DeviceListScreen(),
    addDevice: (context) => const AddDeviceScreen(),
    alertList: (context) => const AlertListScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case deviceDetail:
        final deviceId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => DeviceDetailScreen(deviceId: deviceId),
        );
      case deviceSettings:
        final deviceId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => DeviceSettingsScreen(deviceId: deviceId),
        );
      case alertDetail:
        final alertId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AlertDetailScreen(alertId: alertId),
        );
      default:
        return null;
    }
  }
}
