import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.miao3strikemod/bridge');

  // 权限相关
  static Future<bool> checkAccessibilityPermission() async {
    return await _channel.invokeMethod('checkAccessibilityPermission');
  }

  static Future<bool> requestAccessibilityPermission() async {
    return await _channel.invokeMethod('requestAccessibilityPermission');
  }

  static Future<bool> checkOverlayPermission() async {
    return await _channel.invokeMethod('checkOverlayPermission');
  }

  static Future<bool> requestOverlayPermission() async {
    return await _channel.invokeMethod('requestOverlayPermission');
  }

  // 服务控制
  static Future<bool> startFloatingService() async {
    return await _channel.invokeMethod('startFloatingService');
  }

  static Future<bool> stopFloatingService() async {
    return await _channel.invokeMethod('stopFloatingService');
  }

  static Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod('isServiceRunning');
  }

  static Future<bool> setFunctionEnabled(bool enabled) async {
    return await _channel.invokeMethod('setFunctionEnabled', {'enabled': enabled});
  }

  static Future<bool> isFunctionEnabled() async {
    return await _channel.invokeMethod('isFunctionEnabled');
  }

  // 宏配置
  static Future<Map<String, dynamic>> getMacroConfig() async {
    final config = await _channel.invokeMethod('getMacroConfig');
    return Map<String, dynamic>.from(config ?? {});
  }

  static Future<bool> saveMacroConfig(Map<String, dynamic> config) async {
    return await _channel.invokeMethod('saveMacroConfig', config);
  }

  static Future<bool> resetMacroConfig() async {
    return await _channel.invokeMethod('resetMacroConfig');
  }

  // 平台信息
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    final info = await _channel.invokeMethod('getPlatformInfo');
    return Map<String, dynamic>.from(info ?? {});
  }
}