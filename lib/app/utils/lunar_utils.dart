import '../services/lunar_service.dart';

/// Wrapper class for LunarService to maintain compatibility with lich-am code
/// This is an alias to LunarService
class LunarUtils {
  /// Converts a lunar date to solar (Gregorian) date
  static DateTime convertLunarToSolar(
    DateTime lunarDate, [
    int timeZone = 7,
  ]) {
    try {
      return LunarService.getLunarToSolar(
        lunarDate.day,
        lunarDate.month,
        lunarDate.year,
        false,
        timeZone,
      );
    } catch (e) {
      throw Exception('Failed to convert lunar date to solar date: $e');
    }
  }

  /// Converts a solar (Gregorian) date to lunar date
  static DateTime convertSolarToLunar(
    DateTime solarDate, [
    int timeZone = 7,
  ]) {
    try {
      final lunarDate = LunarService.getSolarToLunar(solarDate, timeZone);
      return DateTime(lunarDate.year, lunarDate.month, lunarDate.day);
    } catch (e) {
      throw Exception('Failed to convert solar date to lunar date: $e');
    }
  }

  /// Gets the first and last day of a lunar month in solar calendar
  static Future<Map<String, DateTime>> getFirstAndLastDayOfLunarMonth(
    int month,
    int year,
  ) async {
    try {
      final firstLunarDay = DateTime(year, month, 1);
      final firstSolarDay = convertLunarToSolar(firstLunarDay);

      DateTime lastLunarDay;
      DateTime lastSolarDay;

      try {
        lastLunarDay = DateTime(year, month, 30);
        lastSolarDay = convertLunarToSolar(lastLunarDay);
      } catch (e) {
        lastLunarDay = DateTime(year, month, 29);
        lastSolarDay = convertLunarToSolar(lastLunarDay);
      }

      return {
        'first': firstSolarDay,
        'last': lastSolarDay,
      };
    } catch (e) {
      throw Exception('Error calculating lunar month range: $e');
    }
  }
}
