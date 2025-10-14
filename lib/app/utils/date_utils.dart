import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format date as DD/MM/YYYY
  static String formatDMY(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as DD-MM-YYYY
  static String formatDMYWithDash(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Format date as YYYY-MM-DD
  static String formatYMD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format time as HH:mm
  static String formatHM(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format full date time as DD/MM/YYYY HH:mm
  static String formatFullDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Parse date string DD/MM/YYYY to DateTime
  static DateTime? parseDMY(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date string YYYY-MM-DD to DateTime
  static DateTime? parseYMD(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get Vietnamese weekday name
  static String getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  /// Get Vietnamese month name
  static String getVietnameseMonth(int month) {
    return 'Tháng $month';
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
