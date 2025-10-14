// Thêm vào đầu file home_module_controller.dart
// Hoặc trong một file model riêng và import vào
class DayEventMarkerInfo {
  final bool hasSystemEvent;
  final bool hasUserEvent;
  final String?
      firstUserEventIconUrl; // Sẽ lấy icon của sự kiện người dùng đầu tiên có icon

  DayEventMarkerInfo({
    this.hasSystemEvent = false,
    this.hasUserEvent = false,
    this.firstUserEventIconUrl,
  });

  // Tiện ích kiểm tra nếu có bất kỳ marker nào cần hiển thị
  bool get hasAnyMarker =>
      hasSystemEvent ||
      (hasUserEvent &&
          firstUserEventIconUrl != null &&
          firstUserEventIconUrl!.isNotEmpty);

// Chuyển đổi sang JSON để gửi đi
  Map<String, dynamic> toJson() {
    return {
      'hasSystemEvent': hasSystemEvent,
      'hasUserEvent': hasUserEvent,
      'firstUserEventIconUrl': firstUserEventIconUrl,
    };
  }
}
