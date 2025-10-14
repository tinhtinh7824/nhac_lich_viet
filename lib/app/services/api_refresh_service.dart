import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/logger_utils.dart';
import '../utils/network_utils.dart';

/// API Refresh Service - Simple service to refresh APIs when network reconnects
/// This service listens to network changes and triggers refresh callbacks
class ApiRefreshService extends GetxService {
  static ApiRefreshService get to => Get.find<ApiRefreshService>();
  
  // Track network state
  bool _wasOffline = false;
  StreamSubscription<ConnectivityResult>? _networkSubscription;
  
  // Callbacks to refresh data
  final List<Function()> _refreshCallbacks = [];
  
  // Prevent multiple refreshes in short time
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);
  
  @override
  void onInit() {
    super.onInit();
    _setupNetworkListener();
    LoggerUtils.info('ApiRefreshService initialized');
  }
  
  @override
  void onClose() {
    _networkSubscription?.cancel();
    _refreshCallbacks.clear();
    super.onClose();
  }
  
  /// Register a callback to be called when network reconnects
  void registerRefreshCallback(Function() callback) {
    if (!_refreshCallbacks.contains(callback)) {
      _refreshCallbacks.add(callback);
      LoggerUtils.debug('Registered refresh callback: ${callback.hashCode}');
    }
  }
  
  /// Unregister a callback
  void unregisterRefreshCallback(Function() callback) {
    _refreshCallbacks.remove(callback);
    LoggerUtils.debug('Unregistered refresh callback: ${callback.hashCode}');
  }
  
  /// Setup network connectivity listener
  void _setupNetworkListener() {
    // Initial state
    _wasOffline = !NetworkUtils.hasConnection;
    
    _networkSubscription = NetworkUtils.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      
      // Check if we're coming back online
      if (_wasOffline && isConnected) {
        LoggerUtils.info('📶 Network reconnected! Triggering API refreshes...');
        _triggerRefreshCallbacks();
      }
      
      _wasOffline = !isConnected;
    });
  }
  
  /// Trigger all registered refresh callbacks
  void _triggerRefreshCallbacks() {
    // Check minimum interval
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        LoggerUtils.debug('Skipping refresh - too soon since last refresh');
        return;
      }
    }
    
    _lastRefreshTime = DateTime.now();
    
    // Execute callbacks with error handling
    for (final callback in _refreshCallbacks) {
      try {
        LoggerUtils.debug('Executing refresh callback: ${callback.hashCode}');
        callback();
      } catch (e) {
        LoggerUtils.error('Error in refresh callback', e);
      }
    }
  }
  
  /// Manually trigger refresh (for testing or user action)
  void manualRefresh() {
    if (NetworkUtils.hasConnection) {
      LoggerUtils.info('Manual refresh triggered');
      _triggerRefreshCallbacks();
    } else {
      LoggerUtils.warning('Cannot refresh - no network connection');
    }
  }
}