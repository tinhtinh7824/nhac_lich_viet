import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'logger_utils.dart';

/// A utility class for network connectivity operations.
class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isInitialized = false;
  static ConnectivityResult _connectionStatus = ConnectivityResult.none;
  static final _connectivityController = StreamController<ConnectivityResult>.broadcast();

  /// Stream that emits connectivity status changes.
  static Stream<ConnectivityResult> get onConnectivityChanged => _connectivityController.stream;

  /// Gets the current connection status.
  static ConnectivityResult get connectionStatus => _connectionStatus;

  /// Initializes the network utils.
  ///
  /// This should be called early in app startup.
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // connectivity_plus 6.x returns List<ConnectivityResult>
      final results = await _connectivity.checkConnectivity();
      _connectionStatus = results.isNotEmpty ? results.first : ConnectivityResult.none;

      _subscription = _connectivity.onConnectivityChanged.listen((resultList) {
        _updateConnectionStatus(resultList.isNotEmpty ? resultList.first : ConnectivityResult.none);
      });
      _isInitialized = true;

      LoggerUtils.debug('NetworkUtils initialized, status: $_connectionStatus');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to initialize NetworkUtils', e, stackTrace);
      rethrow;
    }
  }

  /// Updates the connection status and notifies listeners.
  static void _updateConnectionStatus(ConnectivityResult result) {
    LoggerUtils.debug('Connectivity changed: $result');
    _connectionStatus = result;
    _connectivityController.add(result);
  }

  /// Checks if the device has internet connectivity.
  /// 
  /// This checks for any type of connectivity (WiFi, mobile, ethernet)
  /// but doesn't guarantee full internet access.
  static bool get hasConnection => 
      _connectionStatus == ConnectivityResult.wifi ||
      _connectionStatus == ConnectivityResult.mobile ||
      _connectionStatus == ConnectivityResult.ethernet;

  /// Checks if the device is connected to WiFi.
  static bool get isWifi => _connectionStatus == ConnectivityResult.wifi;

  /// Checks if the device is connected to mobile data.
  static bool get isMobile => _connectionStatus == ConnectivityResult.mobile;

  /// Checks if the device is connected to ethernet.
  static bool get isEthernet => _connectionStatus == ConnectivityResult.ethernet;

  /// Disposes resources.
  /// 
  /// Call this when the app is shutting down or the service is no longer needed.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _connectivityController.close();
    _isInitialized = false;
    LoggerUtils.debug('NetworkUtils disposed');
  }

  /// Gets the connection type as a string.
  static String get connectionType {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
        return 'None';
      default:
        return 'Unknown';
    }
  }

  /// Checks connectivity and returns a result.
  ///
  /// Useful for manually checking the connection status.
  static Future<ConnectivityResult> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
      return result;
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to check connectivity', e, stackTrace);
      return ConnectivityResult.none;
    }
  }
}
