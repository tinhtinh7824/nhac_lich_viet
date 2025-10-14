// data/providers/storage_provider.dart
import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_constants.dart';
import '../../utils/logger_utils.dart';

class StorageProvider {
  // Singleton pattern
  static final StorageProvider _instance = StorageProvider._internal();
  factory StorageProvider() => _instance;
  StorageProvider._internal();

  late SharedPreferences _prefs;
  late GetStorage _box;

  bool _isPrefsInitialized = false;
  bool _isBoxInitialized = false;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isPrefsInitialized = true;
      await GetStorage.init();
      _box = GetStorage();
      _isBoxInitialized = true;
      LoggerUtils.debug(
          'StorageProvider initialized (Prefs: $_isPrefsInitialized, Box: $_isBoxInitialized)');
    } catch (e) {
      LoggerUtils.error('Failed to initialize StorageProvider', e);
      if (!_isPrefsInitialized) {
        try {
          _prefs = await SharedPreferences.getInstance();
          _isPrefsInitialized = true;
          LoggerUtils.warning(
              'GetStorage init failed, using SharedPreferences only.');
        } catch (prefsError) {
          LoggerUtils.error(
              'SharedPreferences also failed to initialize', prefsError);
          rethrow;
        }
      } else if (!_isBoxInitialized) {
        LoggerUtils.warning(
            'GetStorage init failed. Some GetStorage specific functions might not work.');
      }
    }
  }

  // Generic methods for GetStorage
  T? read<T>(String key) {
    if (!_isBoxInitialized) {
      LoggerUtils.warning("GetStorage not initialized. Cannot read key: $key");
      if (_isPrefsInitialized) {
        if (T == String) return _prefs.getString(key) as T?;
        if (T == int) return _prefs.getInt(key) as T?;
        if (T == bool) return _prefs.getBool(key) as T?;
        if (T == double) return _prefs.getDouble(key) as T?;
      }
      return null;
    }
    try {
      return _box.read<T>(key);
    } catch (e) {
      LoggerUtils.error('Failed to read $key from GetStorage', e);
      return null;
    }
  }

  Future<void> write(String key, dynamic value) async {
    if (!_isBoxInitialized) {
      LoggerUtils.warning("GetStorage not initialized. Cannot write key: $key");
      if (_isPrefsInitialized) {
        if (value is String) {
          await _prefs.setString(key, value);
        } else if (value is int) {
          await _prefs.setInt(key, value);
        } else if (value is bool) {
          await _prefs.setBool(key, value);
        } else if (value is double) {
          await _prefs.setDouble(key, value);
        } else {
          LoggerUtils.warning(
              "Unsupported type for SharedPreferences fallback write: ${value.runtimeType}");
        }
        return;
      }
      throw Exception("GetStorage not initialized and cannot write key: $key");
    }
    try {
      await _box.write(key, value);
    } catch (e) {
      LoggerUtils.error('Failed to write $key to GetStorage', e);
      rethrow;
    }
  }

  // Specific methods for common data
  Future<void> saveToken(String token) async {
    await write(AppConstants.storageTokenKey, token);
  }

  String? getToken() {
    return read<String>(AppConstants.storageTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await write(AppConstants.storageRefreshTokenKey, token);
  }

  String? getRefreshToken() {
    return read<String>(AppConstants.storageRefreshTokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await write(AppConstants.storageUserKey, jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final userStr = read<String>(AppConstants.storageUserKey);
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (e) {
      LoggerUtils.error('Failed to decode user data', e);
      return null;
    }
  }

  Future<void> saveLanguage(String languageCode) async {
    await write(AppConstants.storageLanguageKey, languageCode);
  }

  String getLanguage() {
    return read<String>(AppConstants.storageLanguageKey) ??
        AppConstants.defaultLanguage;
  }

  Future<void> saveThemeMode(String themeMode) async {
    await write(AppConstants.storageThemeModeKey, themeMode);
  }

  String? getThemeMode() {
    return read<String>(AppConstants.storageThemeModeKey);
  }

  Future<void> clearAuthData() async {
    if (_isBoxInitialized) {
      await _box.remove(AppConstants.storageTokenKey);
      await _box.remove(AppConstants.storageRefreshTokenKey);
      await _box.remove(AppConstants.storageUserKey);
    } else if (_isPrefsInitialized) {
      await _prefs.remove(AppConstants.storageTokenKey);
      await _prefs.remove(AppConstants.storageRefreshTokenKey);
      await _prefs.remove(AppConstants.storageUserKey);
    }
  }

  bool hasData(String key) {
    if (_isBoxInitialized) {
      return _box.hasData(key);
    } else if (_isPrefsInitialized) {
      return _prefs.containsKey(key);
    }
    return false;
  }

  Future<void> clearAll() async {
    if (_isBoxInitialized) await _box.erase();
    if (_isPrefsInitialized) await _prefs.clear();
  }

  Future<bool> setString(String key, String value) async {
    if (!_isPrefsInitialized) {
      LoggerUtils.warning(
          "SharedPreferences not initialized. Cannot setString for key: $key");
      return false;
    }
    return await _prefs.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    if (!_isPrefsInitialized) return defaultValue;
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) async {
    if (!_isPrefsInitialized) return false;
    return await _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    if (!_isPrefsInitialized) return defaultValue;
    return _prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) async {
    if (!_isPrefsInitialized) return false;
    return await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    if (!_isPrefsInitialized) return defaultValue;
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) async {
    if (!_isPrefsInitialized) return false;
    return await _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    if (!_isPrefsInitialized) return defaultValue;
    return _prefs.getDouble(key) ?? defaultValue;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    if (!_isPrefsInitialized) return false;
    return await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key,
      {List<String> defaultValue = const []}) {
    if (!_isPrefsInitialized) return defaultValue;
    return _prefs.getStringList(key) ?? defaultValue;
  }

  Future<bool> remove(String key) async {
    bool boxRemoved = false;
    bool prefsRemoved = false;

    if (_isBoxInitialized) {
      try {
        await _box.remove(key);
        boxRemoved = true;
      } catch (e) {
        LoggerUtils.error("Error removing key $key from GetStorage", e);
      }
    }

    if (_isPrefsInitialized && _prefs.containsKey(key)) {
      try {
        prefsRemoved = await _prefs.remove(key);
      } catch (e) {
        LoggerUtils.error("Error removing key $key from SharedPreferences", e);
      }
    }
    if (!_isBoxInitialized && !_isPrefsInitialized) {
      LoggerUtils.warning(
          "StorageProvider remove failed: Neither GetStorage nor SharedPreferences is initialized for key: $key");
      return false;
    }
    return boxRemoved || prefsRemoved || (!hasData(key));
  }

  Future<void> setUserHasBeenRedirectedToStore(bool value) async {
    try {
      await setBool(AppConstants.storageUserHasBeenRedirectedToStoreKey, value);
      LoggerUtils.debug('Set user_redirected_to_store to: $value');
    } catch (e) {
      LoggerUtils.error('Failed to set user_redirected_to_store flag', e);
    }
  }

  bool getUserHasBeenRedirectedToStore() {
    try {
      return getBool(AppConstants.storageUserHasBeenRedirectedToStoreKey,
          defaultValue: false);
    } catch (e) {
      LoggerUtils.error('Failed to get user_redirected_to_store flag', e);
      return false;
    }
  }

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
  }

  String _getLastPopupCheckKey() {
    return 'lastPopupCheckTimestamp_dailyEvents';
  }

  String _getShownEventIdsKey(String dateString) {
    return 'shownEventIds_dailyEvents_$dateString';
  }

  Future<void> setLastPopupCheckTimestamp() async {
    final String todayString = _getTodayDateString();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      await write(_getLastPopupCheckKey(), timestamp);
      LoggerUtils.info(
          'Đã lưu timestamp kiểm tra popup cho ngày $todayString: $timestamp');
    } catch (e) {
      LoggerUtils.error(
          'Lỗi khi lưu timestamp kiểm tra popup cho ngày $todayString', e);
    }
  }

  int? getLastPopupCheckTimestamp() {
    try {
      return read<int>(_getLastPopupCheckKey());
    } catch (e) {
      LoggerUtils.error('Lỗi khi lấy timestamp kiểm tra popup', e);
      return null;
    }
  }

  Future<void> addShownEventId(String eventId) async {
    final String todayString = _getTodayDateString();
    final String key = _getShownEventIdsKey(todayString);
    try {
      List<String> shownIds = getShownEventIdsForDate(todayString);
      if (!shownIds.contains(eventId)) {
        shownIds.add(eventId);
        await write(key, shownIds);
        LoggerUtils.debug(
            'Đã thêm eventId $eventId vào danh sách đã hiển thị cho ngày $todayString');
      }
    } catch (e) {
      LoggerUtils.error(
          'Lỗi khi thêm eventId $eventId cho ngày $todayString', e);
    }
  }

  List<String> getShownEventIdsForDate(String dateString) {
    final String key = _getShownEventIdsKey(dateString);
    try {
      final List<dynamic>? storedValue = read<List<dynamic>>(key);
      if (storedValue != null) {
        return List<String>.from(storedValue.map((item) => item.toString()));
      }
      return [];
    } catch (e) {
      LoggerUtils.error(
          'Lỗi khi lấy danh sách eventId đã hiển thị cho ngày $dateString', e);
      return [];
    }
  }

  Future<void> clearOldPopupData({int daysToKeep = 1}) async {
    if (!_isBoxInitialized) {
      LoggerUtils.warning(
          "GetStorage not initialized in clearOldPopupData. Skipping.");
      return;
    }
    try {
      final List<String> keys = _box.getKeys().cast<String>().toList();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      for (var key in keys) {
        if (key.startsWith('shownEventIds_dailyEvents_')) {
          try {
            final dateString =
                key.substring('shownEventIds_dailyEvents_'.length);
            final eventDate = dateFormat.parse(dateString);
            if (eventDate.isBefore(cutoffDate)) {
              await remove(key);
              LoggerUtils.info('Đã xóa dữ liệu popup cũ: $key');
            }
          } catch (e) {
            LoggerUtils.warning("Lỗi khi xử lý key cache cũ: $key - $e");
          }
        }
      }
    } catch (e) {
      LoggerUtils.error('Lỗi khi xóa dữ liệu popup cũ', e);
    }
  }

  Future<void> clearTodaysPopupFlagsForDebugging() async {
    final String todayString = _getTodayDateString();
    final String todayShownEventsKey = _getShownEventIdsKey(todayString);
    final String lastCheckKey = _getLastPopupCheckKey();

    try {
      if (hasData(todayShownEventsKey)) {
        await remove(todayShownEventsKey);
        LoggerUtils.debug(
            'DEBUG: Đã xóa cờ sự kiện đã hiển thị hôm nay ($todayShownEventsKey).');
      } else {
        LoggerUtils.debug(
            'DEBUG: Không có cờ sự kiện đã hiển thị hôm nay để xóa ($todayShownEventsKey).');
      }
      await write(lastCheckKey, 0);
      LoggerUtils.debug(
          'DEBUG: Đã reset thời gian kiểm tra popup cuối cùng ($lastCheckKey).');
    } catch (e) {
      LoggerUtils.error('DEBUG: Lỗi khi xóa cờ popup hôm nay cho debug', e);
    }
  }
}
