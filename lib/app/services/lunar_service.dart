import 'package:vnlunar/vnlunar.dart';

/// Vietnamese Lunar Calendar Service
class LunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeapMonth;

  LunarDate({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });

  @override
  String toString() => '$day-$month${isLeapMonth ? " nhuận" : ""} âm lịch';
}

class LunarService {
  /// Convert solar (dương lịch) date to lunar (âm lịch) date
  static LunarDate getSolarToLunar(DateTime solarDate, [int timeZone = 7]) {
    try {
      final lunarInfo = convertSolar2Lunar(
        solarDate.day,
        solarDate.month,
        solarDate.year,
        timeZone,
      );

      if (lunarInfo.isEmpty || lunarInfo.length < 3) {
        throw Exception('Invalid result from solar to lunar conversion');
      }

      return LunarDate(
        day: lunarInfo[0],
        month: lunarInfo[1],
        year: lunarInfo[2],
        isLeapMonth: lunarInfo.length > 3 && lunarInfo[3] == 1,
      );
    } catch (e) {
      throw Exception('Failed to convert solar date to lunar date: $e');
    }
  }

  /// Convert lunar (âm lịch) date to solar (dương lịch) date
  static DateTime getLunarToSolar(
    int lunarDay,
    int lunarMonth,
    int lunarYear, [
    bool isLeapMonth = false,
    int timeZone = 7,
  ]) {
    try {
      final solarDate = convertLunar2Solar(
        lunarDay,
        lunarMonth,
        lunarYear,
        isLeapMonth,
        timeZone,
      );

      if (solarDate[0] == 0 && solarDate[1] == 0 && solarDate[2] == 0) {
        throw Exception('Unable to convert lunar date to solar date');
      }

      return DateTime(solarDate[2], solarDate[1], solarDate[0]);
    } catch (e) {
      throw Exception('Failed to convert lunar date to solar date: $e');
    }
  }
}
