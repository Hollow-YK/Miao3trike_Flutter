import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 更新管理器 - 管理更新渠道和镜像设置（单例模式）
class UpdateManager {
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  static const String _keyUpdateChannel = 'update_channel';
  static const String _keyUseMirror = 'use_mirror';
  static const String _keyMirrorUrl = 'mirror_url';

  static const String _defaultChannel = 'github';
  static const bool _defaultUseMirror = false;
  static const String _defaultMirrorUrl = 'https://mirror.ghproxy.com/';

  String _updateChannel = _defaultChannel;
  bool _useMirror = _defaultUseMirror;
  String _mirrorUrl = _defaultMirrorUrl;

  /// 当前更新渠道
  String get updateChannel => _updateChannel;

  /// 是否使用镜像
  bool get useMirror => _useMirror;

  /// 镜像地址
  String get mirrorUrl => _mirrorUrl;

  /// 初始化（从本地存储加载设置）
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _updateChannel = prefs.getString(_keyUpdateChannel) ?? _defaultChannel;
      _useMirror = prefs.getBool(_keyUseMirror) ?? _defaultUseMirror;
      _mirrorUrl = prefs.getString(_keyMirrorUrl) ?? _defaultMirrorUrl;
    } catch (e) {
      debugPrint('加载更新设置失败: $e');
      // 使用默认值
      _updateChannel = _defaultChannel;
      _useMirror = _defaultUseMirror;
      _mirrorUrl = _defaultMirrorUrl;
    }
  }

  /// 获取版本检查URL
  String getVersionCheckUrl({required bool isBeta}) {
    final String baseUrl;

    if (_updateChannel == 'gitee') {
      // Gitee渠道
      baseUrl = isBeta
          ? 'https://gitee.com/hollow_YK/Miao3trike_Flutter/raw/Dev/version.json'
          : 'https://gitee.com/Hollow_YK/Miao3trike_Flutter/raw/main/version.json';
    } else {
      // GitHub渠道
      final String githubUrl = isBeta
          ? 'https://raw.githubusercontent.com/Hollow-YK/Miao3trike_Flutter/Dev/version.json'
          : 'https://raw.githubusercontent.com/Hollow-YK/Miao3trike_Flutter/main/version.json';

      if (_useMirror && _mirrorUrl.isNotEmpty) {
        // 应用镜像地址格式：https://example.com/{url}
        final String mirror = _mirrorUrl.endsWith('/')
            ? _mirrorUrl
            : '$_mirrorUrl/';
        baseUrl = '$mirror$githubUrl';
      } else {
        baseUrl = githubUrl;
      }
    }

    return baseUrl;
  }

  /// 获取GitHub Release页面URL
  String getGitHubReleaseUrl() {
    const String githubReleaseUrl =
        'https://github.com/Hollow-YK/Miao3trike_Flutter/releases';

    if (_updateChannel == 'github' && _useMirror && _mirrorUrl.isNotEmpty) {
      // 应用镜像地址格式：https://example.com/{url}
      final String mirror = _mirrorUrl.endsWith('/')
          ? _mirrorUrl
          : '$_mirrorUrl/';
      return '$mirror$githubReleaseUrl';
    }

    return githubReleaseUrl;
  }

  /// 设置更新渠道
  Future<void> setUpdateChannel(String channel) async {
    if (_updateChannel != channel) {
      _updateChannel = channel;
      _saveToPrefs(_keyUpdateChannel, channel);
    }
  }

  /// 设置是否使用镜像
  Future<void> setUseMirror(bool use) async {
    if (_useMirror != use) {
      _useMirror = use;
      _saveToPrefs(_keyUseMirror, use);
    }
  }

  /// 设置镜像地址
  Future<void> setMirrorUrl(String url) async {
    final trimmedUrl = url.trim();
    if (_mirrorUrl != trimmedUrl) {
      _mirrorUrl = trimmedUrl;
      _saveToPrefs(_keyMirrorUrl, trimmedUrl);
    }
  }

  /// 测试镜像连接
  Future<bool> testMirrorConnection() async {
    // 这里可以添加实际的网络测试逻辑
    // 暂时简单验证URL格式
    return _mirrorUrl.isNotEmpty &&
        (_mirrorUrl.startsWith('http://') || _mirrorUrl.startsWith('https://'));
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    _updateChannel = _defaultChannel;
    _useMirror = _defaultUseMirror;
    _mirrorUrl = _defaultMirrorUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUpdateChannel, _defaultChannel);
    await prefs.setBool(_keyUseMirror, _defaultUseMirror);
    await prefs.setString(_keyMirrorUrl, _defaultMirrorUrl);
  }

  /// 保存到SharedPreferences
  Future<void> _saveToPrefs(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      debugPrint('保存设置失败 ($key: $value): $e');
    }
  }
}

/// URL验证辅助函数
bool isValidUrl(String url) {
  return url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));
}
