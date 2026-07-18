import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A global registry and manager for [MobileScannerController] instances
/// to ensure only one scanner runs at any time, preventing resource contention.
class CameraLifecycleManager {
  static final CameraLifecycleManager instance = CameraLifecycleManager._();
  CameraLifecycleManager._();

  MobileScannerController? _activeController;

  /// Registers a controller and starts it after stopping any previously active controller.
  Future<void> registerAndStart(MobileScannerController controller) async {
    // If there is another active controller running, stop it first.
    if (_activeController != null && _activeController != controller) {
      debugPrint('[CameraLifecycleManager] Stopping previously active scanner controller.');
      try {
        await _activeController!.stop();
      } catch (e) {
        debugPrint('[CameraLifecycleManager] Error stopping previous scanner: $e');
      }
    }

    _activeController = controller;

    // Start the new controller if it's not already running.
    if (!controller.value.isRunning) {
      debugPrint('[CameraLifecycleManager] Starting new scanner controller.');
      try {
        await controller.start();
      } catch (e) {
        debugPrint('[CameraLifecycleManager] Error starting new scanner: $e');
      }
    }
  }

  /// Stops the currently active controller, if any.
  Future<void> stopActive() async {
    if (_activeController != null) {
      debugPrint('[CameraLifecycleManager] Stopping active scanner controller.');
      try {
        await _activeController!.stop();
      } catch (e) {
        debugPrint('[CameraLifecycleManager] Error stopping active scanner: $e');
      }
    }
  }

  /// Unregisters the controller when it is disposed.
  void unregister(MobileScannerController controller) {
    if (_activeController == controller) {
      debugPrint('[CameraLifecycleManager] Unregistering active scanner controller.');
      _activeController = null;
    }
  }
}
