import 'package:flutter/material.dart';

/// Bổ sung getter tương thích cho các package cũ (ví dụ showcaseview)
extension TextThemeCompatibility on TextTheme {
  TextStyle? get headline6 => titleLarge;
  TextStyle? get subtitle2 => titleMedium;
}
