/// Application configuration management
/// This file handles loading configuration from environment variables
/// or falls back to default values for development
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // API Configuration
  static const String _defaultHost = "YOUR_BACKEND_HOST";
  static const String _defaultProjectId = "YOUR_PROJECT_ID";

  // Firebase Web Configuration
  static const String _defaultWebApiKey = "YOUR_WEB_API_KEY";
  static const String _defaultWebAppId = "YOUR_WEB_APP_ID";
  static const String _defaultMessagingSenderId = "YOUR_MESSAGING_SENDER_ID";
  static const String _defaultMeasurementId = "YOUR_MEASUREMENT_ID";

  // Firebase Android Configuration
  static const String _defaultAndroidApiKey = "YOUR_ANDROID_API_KEY";
  static const String _defaultAndroidAppId = "YOUR_ANDROID_APP_ID";

  // Firebase iOS Configuration
  static const String _defaultIosApiKey = "YOUR_IOS_API_KEY";
  static const String _defaultIosAppId = "YOUR_IOS_APP_ID";

  // Firebase macOS Configuration
  static const String _defaultMacosApiKey = "YOUR_MACOS_API_KEY";
  static const String _defaultMacosAppId = "YOUR_MACOS_APP_ID";

  // API Configuration Getters
  static String get backendHost {
    return const String.fromEnvironment(
      'BACKEND_HOST',
      defaultValue: _defaultHost,
    );
  }

  static String get projectId {
    return const String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: _defaultProjectId,
    );
  }

  // Firebase Web Configuration Getters
  static String get webApiKey {
    return const String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: _defaultWebApiKey,
    );
  }

  static String get webAppId {
    return const String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: _defaultWebAppId,
    );
  }

  static String get messagingSenderId {
    return const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: _defaultMessagingSenderId,
    );
  }

  static String get measurementId {
    return const String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
      defaultValue: _defaultMeasurementId,
    );
  }

  // Firebase Android Configuration Getters
  static String get androidApiKey {
    return const String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: _defaultAndroidApiKey,
    );
  }

  static String get androidAppId {
    return const String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: _defaultAndroidAppId,
    );
  }

  // Firebase iOS Configuration Getters
  static String get iosApiKey {
    return const String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: _defaultIosApiKey,
    );
  }

  static String get iosAppId {
    return const String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: _defaultIosAppId,
    );
  }

  // Firebase macOS Configuration Getters
  static String get macosApiKey {
    return const String.fromEnvironment(
      'FIREBASE_MACOS_API_KEY',
      defaultValue: _defaultMacosApiKey,
    );
  }

  static String get macosAppId {
    return const String.fromEnvironment(
      'FIREBASE_MACOS_APP_ID',
      defaultValue: _defaultMacosAppId,
    );
  }

  // Computed properties
  static String get authDomain => '$projectId.firebaseapp.com';
  static String get storageBucket => '$projectId.appspot.com';
}
