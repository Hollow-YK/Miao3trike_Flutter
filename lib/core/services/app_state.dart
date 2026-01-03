import 'package:flutter/foundation.dart';
import 'package:miao3trikeflutter/core/native_bridge.dart';

class AppState extends ChangeNotifier {
  bool _isAccessibilityEnabled = false;
  bool _isOverlayPermissionGranted = false;
  bool _isServiceRunning = false;
  bool _isFunctionEnabled = false;
  Map<String, dynamic> _macroConfig = {};
  bool _isLoading = false;

  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isOverlayPermissionGranted => _isOverlayPermissionGranted;
  bool get isServiceRunning => _isServiceRunning;
  bool get isFunctionEnabled => _isFunctionEnabled;
  Map<String, dynamic> get macroConfig => _macroConfig;
  bool get isLoading => _isLoading;

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        NativeBridge.checkAccessibilityPermission(),
        NativeBridge.checkOverlayPermission(),
        NativeBridge.isServiceRunning(),
        NativeBridge.isFunctionEnabled(),
        NativeBridge.getMacroConfig(),
      ]);

      _isAccessibilityEnabled = results[0] as bool;
      _isOverlayPermissionGranted = results[1] as bool;
      _isServiceRunning = results[2] as bool;
      _isFunctionEnabled = results[3] as bool;
      _macroConfig = results[4] as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('刷新状态失败: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleService() async {
    if (!_isAccessibilityEnabled) {
      await NativeBridge.requestAccessibilityPermission();
      return;
    }

    if (!_isOverlayPermissionGranted) {
      await NativeBridge.requestOverlayPermission();
      return;
    }

    if (_isServiceRunning) {
      await NativeBridge.stopFloatingService();
    } else {
      await NativeBridge.startFloatingService();
    }

    await refreshAll();
  }

  Future<void> toggleFunction() async {
    await NativeBridge.setFunctionEnabled(!_isFunctionEnabled);
    await refreshAll();
  }

  Future<void> updateMacroConfig(Map<String, dynamic> config) async {
    await NativeBridge.saveMacroConfig(config);
    await refreshAll();
  }

  Future<void> resetMacroConfig() async {
    await NativeBridge.resetMacroConfig();
    await refreshAll();
  }
}