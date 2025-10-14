class AppConstants {
  // App
  static const String appName = 'Nhắc Lịch Việt';

  // API Constants
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const String contentType = 'application/json';

  // Storage Keys
  static const String storageUserKey = 'user';
  static const String storageTokenKey = 'token';
  static const String storageRefreshTokenKey = 'refreshToken';
  static const String storageLanguageKey = 'language';
  static const String storageThemeModeKey = 'themeMode';

  // Defaults
  static const String defaultLanguage = 'vi';
  static const String defaultCountryCode = 'VN';

  // Hive Boxes
  static const String userBox = 'userBox';
  static const String settingsBox = 'settingsBox';
  static const String cacheBox = 'cacheBox';
  static const String offlineRequestsBox = 'offlineRequestsBox';
  static const String filesBox = 'filesBox';

  // File related constants
  static const int defaultUploadChunkSize = 1024 * 1024; // 1MB
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Cache Constants
  static const int defaultCacheExpirationHours = 24; // 24 hours
  static const bool enableOfflineMode = true;

  // Event Storage Keys
  static const String storageUserHasBeenRedirectedToStoreKey =
      'user_redirected_to_store';
}
