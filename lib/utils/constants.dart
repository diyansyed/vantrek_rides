/// App Constants
class AppConstants {
  // App Info
  static const String appName = 'Vantrek';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  static const String driversCollection = 'drivers';

  // User Types
  static const String userTypeUser = 'user';
  static const String userTypeDriver = 'driver';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
}

/// App Colors
class AppColors {
  static const primaryBlue = 0xFF2196F3;
  static const lightBlue = 0xFF64B5F6;
  static const darkBlue = 0xFF1976D2;

  static const orange = 0xFFFF9800;
  static const lightOrange = 0xFFFFB74D;

  static const success = 0xFF4CAF50;
  static const error = 0xFFF44336;
  static const warning = 0xFFFF9800;
  static const info = 0xFF2196F3;

  static const background = 0xFFFAFAFA;
  static const surface = 0xFFFFFFFF;
  static const divider = 0xFFE0E0E0;
}

/// Regular Expressions for Validation
class AppRegex {
  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final phoneRegex = RegExp(
    r'^\+?[\d\s-()]+$',
  );

  static final nameRegex = RegExp(
    r'^[a-zA-Z\s]+$',
  );
}