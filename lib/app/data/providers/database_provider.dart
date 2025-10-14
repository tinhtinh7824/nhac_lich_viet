import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/logger_utils.dart';

class DatabaseProvider extends GetxService {
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      // Hive is already initialized in main.dart
      // Just verify it's ready
      LoggerUtils.debug('DatabaseProvider ready - Hive already initialized in main.dart');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to initialize DatabaseProvider', e, stackTrace);
      rethrow;
    }
  }

  /// Open a Hive box with a specific type
  Future<Box<T>> openBox<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        LoggerUtils.debug('Box $boxName is already open');
        return Hive.box<T>(boxName);
      }

      final box = await Hive.openBox<T>(boxName);
      LoggerUtils.debug('Opened box: $boxName');
      return box;
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to open box: $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Close a specific box
  Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        LoggerUtils.debug('Closed box: $boxName');
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to close box: $boxName', e, stackTrace);
    }
  }

  /// Delete a box
  Future<void> deleteBox(String boxName) async {
    try {
      await Hive.deleteBoxFromDisk(boxName);
      LoggerUtils.debug('Deleted box: $boxName');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to delete box: $boxName', e, stackTrace);
    }
  }

  /// Check if a box exists
  bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  /// Close all boxes
  Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
      LoggerUtils.debug('Closed all Hive boxes');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to close all boxes', e, stackTrace);
    }
  }
}
