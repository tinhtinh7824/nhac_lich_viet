import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  final String title;
  final String iconUrl;
  final String description;
  final Color color;
  final int priority;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bannerUrl;

  EventCategory({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.description,
    required this.color,
    required this.priority,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
    this.bannerUrl,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      title: json['title'],
      iconUrl: json['iconUrl'],
      description: json['description'],
      color: _hexToColor(json['color']),
      priority: json['priority'],
      isSystem: json['isSystem'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      bannerUrl: json['bannerUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconUrl': iconUrl,
      'description': description,
      'color': _colorToHex(color),
      'priority': priority,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bannerUrl': bannerUrl,
    };
  }

  // Chuyển đổi mã màu hex thành Color
  static Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Chuyển đổi Color thành mã màu hex
  static String _colorToHex(Color color) {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).substring(2, 8)}';
  }
}
