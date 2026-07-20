import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A global registry and manager for [MobileScannerController] instances
/// to ensure only one scanner runs at any time, preventing resource contention
/// and handling app lifecycle events (pause/resume).
class CameraLifecycleManager with WidgetsBindingObserver {
  static final CameraLifecycleManager instance = CameraLifecycleManager._();
  bool _isObserverRegistered = false;

  CameraLifecycleManager._() {
    _ensureObserver();
  }

  void _ensureObserver() {
    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }
  }

  MobileScannerController? _activeController;

  /// Returns the currently active controller, if any.
  MobileScannerController? get activeController => _activeController;

  /// Registers a controller and starts it after stopping any previously active controller.
  Future<void> registerAndStart(MobileScannerController controller) async {
    _ensureObserver();
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

    debugPrint('[CameraLifecycleManager] Registering & starting scanner controller.');
    try {
      if (controller.value.isRunning) {
        await controller.stop();
      }
      await controller.start();
    } catch (e) {
      debugPrint('[CameraLifecycleManager] Error starting new scanner: $e');
    }
  }

  /// Restarts the currently active controller, re-creating camera hardware stream.
  Future<void> restartActive() async {
    if (_activeController != null) {
      debugPrint('[CameraLifecycleManager] Restarting active scanner controller on app resume.');
      final controller = _activeController!;
      try {
        await controller.stop();
      } catch (e) {
        debugPrint('[CameraLifecycleManager] Error stopping active scanner before restart: $e');
      }
      try {
        await controller.start();
      } catch (e) {
        debugPrint('[CameraLifecycleManager] Error starting active scanner on restart: $e');
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[CameraLifecycleManager] App resumed -> Restarting active scanner');
      restartActive();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      debugPrint('[CameraLifecycleManager] App paused/inactive -> Stopping active scanner');
      stopActive();
    }
  }
}
