import 'package:vnlunar/vnlunar.dart';

/// Simple lunar date representation
/// Compatible with vnlunar package
class LunarDateTime {
  final int day;
  final int month;
  final int year;
  final bool isLeapMonth;

  LunarDateTime({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });
}

/// Simple wrapper for lunar calendar operations
/// Provides compatibility layer using vnlunar package
class LunarService {
  // Cache for lunar dates to improve performance
  static final Map<String, LunarDateTime> _lunarDateCache = {};

  /// Convert solar (Gregorian) date to lunar (Vietnamese) date
  ///
  /// Example:
  /// ```dart
  /// final solarDate = DateTime(2024, 1, 15);
  /// final lunarDate = LunarService.getSolarToLunar(solarDate);
  /// print('${lunarDate.day}-${lunarDate.month} âm lịch');
  /// ```
  static LunarDateTime getSolarToLunar(DateTime date) {
    // Create cache key
    final localDate = date.toLocal();
    final key = '${localDate.year}-${localDate.month}-${localDate.day}';

    // Check cache first
    if (_lunarDateCache.containsKey(key)) {
      return _lunarDateCache[key]!;
    }

    // Convert solar to lunar using vnlunar package
    try {
      // convertSolar2Lunar returns [lunarDay, lunarMonth, lunarYear, lunarLeap]
      final result = convertSolar2Lunar(
        localDate.day,
        localDate.month,
        localDate.year,
      );

      final lunarDate = LunarDateTime(
        day: result[0],      // lunarDay
        month: result[1],    // lunarMonth
        year: result[2],     // lunarYear
        isLeapMonth: result[3] == 1,  // lunarLeap
      );

      // Cache the result
      _lunarDateCache[key] = lunarDate;

      return lunarDate;
    } catch (e) {
      // If conversion fails, return a default lunar date
      // This prevents crashes in the UI
      final fallback = LunarDateTime(
        day: 1,
        month: 1,
        year: localDate.year - 621, // Approximate lunar year
        isLeapMonth: false,
      );

      return fallback;
    }
  }

  /// Clear the lunar date cache
  /// Useful for memory management in long-running apps
  static void clearCache() {
    _lunarDateCache.clear();
  }

  /// Get cache size (for debugging)
  static int getCacheSize() {
    return _lunarDateCache.length;
  }
}
