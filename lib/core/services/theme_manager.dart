import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 颜色选项类 - 包含颜色值和对应的名称
class ColorOption {
  final Color color;
  final String name;
  final bool isCustom;
  
  const ColorOption({
    required this.color,
    required this.name,
    this.isCustom = false,
  });
}

/// 主题管理器类 - 负责管理应用主题相关的数据和配置
class ThemeManager with ChangeNotifier {
  // 私有构造函数
  ThemeManager._internal();
  
  // 单例实例
  static final ThemeManager _instance = ThemeManager._internal();
  
  /// 获取主题管理器单例
  factory ThemeManager() => _instance;
  
  // SharedPreferences 实例
  SharedPreferences? _prefs;
  
  /// 预定义颜色选项列表
  final List<ColorOption> predefinedColors = [
    const ColorOption(color: Colors.red, name: '红'),      // Material Red
    const ColorOption(color: Colors.pink, name: '粉'),      // Material Pink
    const ColorOption(color: Colors.purple, name: '紫'),        // Material Purple
    const ColorOption(color: Colors.deepPurple, name: '深紫'),        // Material deepPurple
    const ColorOption(color: Colors.indigo, name: '紫'),        // Material Purple
    const ColorOption(color: Colors.blue, name: '蓝'),      // Material Blue
    const ColorOption(color: Colors.lightBlue, name: '浅蓝'),      // Material lightBlue
    const ColorOption(color: Colors.cyan, name: '青'),      // Material Cyan
    const ColorOption(color: Colors.teal, name: '深青'),      // Material Teal
    const ColorOption(color: Colors.green, name: '绿'),      // Material Green
    const ColorOption(color: Colors.lightGreen, name: '浅绿'),      // Material lightGreen
    const ColorOption(color: Colors.lime, name: '黄绿'),      // Material Lime
    const ColorOption(color: Colors.yellow, name: '黄'),      // Material Yellow
    const ColorOption(color: Colors.amber, name: '琥珀'),      // Material Amber
    const ColorOption(color: Colors.orange, name: '橙'),      // Material Orange
    const ColorOption(color: Colors.deepOrange, name: '深橙'),      // Material deepOrange
  ];
  
  /// 自定义颜色列表
  final List<ColorOption> _customColors = [];

  /// 获取自定义颜色列表（公开访问）
  List<ColorOption> get customColors => List.unmodifiable(_customColors);

  // 内部状态变量
  String _themeMode = 'system';
  int _seedColor = 0x3264FF; // 默认种子颜色（蓝色）

  /// 获取所有颜色选项（预定义 + 自定义）
  List<ColorOption> get allColors {
    return [...predefinedColors, ..._customColors];
  }
  
  /// 获取当前主题模式
  String get themeMode => _themeMode;
  
  /// 获取当前种子颜色
  Color get seedColor => Color(_seedColor);

  /// 初始化主题管理器
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// 加载保存的设置
  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    // 加载主题模式
    final savedThemeMode = _prefs!.getString('themeMode');
    if (savedThemeMode != null && ['system', 'light', 'dark'].contains(savedThemeMode)) {
      _themeMode = savedThemeMode;
    }
    
    // 加载主题颜色
    final savedColor = _prefs!.getInt('seedColor');
    if (savedColor != null) {
      _seedColor = savedColor;
    }
    
    // 加载自定义颜色
    final savedCustomColors = _prefs!.getStringList('customColors');
    if (savedCustomColors != null) {
      _customColors.clear();
      for (final colorStr in savedCustomColors) {
        try {
          final parts = colorStr.split('|');
          if (parts.length == 2) {
            final colorValue = int.parse(parts[0]);
            final colorName = parts[1];
            _customColors.add(ColorOption(
              color: Color(colorValue),
              name: colorName,
              isCustom: true,
            ));
          }
        } catch (e) {
          print('加载自定义颜色失败: $e');
        }
      }
    }
    
    notifyListeners();
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (_prefs == null) return;
    
    await _prefs!.setString('themeMode', _themeMode);
    await _prefs!.setInt('seedColor', _seedColor);
    
    // 保存自定义颜色
    final customColorsStr = _customColors.map((color) => 
      '${color.color.value}|${color.name}').toList();
    await _prefs!.setStringList('customColors', customColorsStr);
  }

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    if (mode != 'system' && mode != 'light' && mode != 'dark') {
      throw ArgumentError('主题模式必须是 system、light 或 dark');
    }
    
    _themeMode = mode;
    await _saveSettings();
    notifyListeners();
  }

  /// 设置种子颜色
  Future<void> setSeedColor(Color color) async {
    _seedColor = color.value;
    await _saveSettings();
    notifyListeners();
  }

  /// 添加自定义颜色
  Future<void> addCustomColor(Color color, String name) async {
    // 检查是否已存在相同颜色的自定义颜色
    if (!_customColors.any((c) => c.color.value == color.value)) {
      _customColors.insert(0, ColorOption(
        color: color,
        name: name,
        isCustom: true,
      ));
      
      // 限制自定义颜色数量，最多保存10个
      if (_customColors.length > 10) {
        _customColors.removeLast();
      }
      
      await _saveSettings();
      notifyListeners();
    }
  }

  /// 通过十六进制字符串添加颜色
  Future<void> addCustomColorFromHex(String hexString, String name) async {
    try {
      // 清理十六进制字符串
      String hex = hexString.replaceAll('#', '').toUpperCase();
      
      // 处理3位简写格式（如 #FFF）
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }
      
      // 确保是6位十六进制数
      if (hex.length == 6) {
        final color = Color(int.parse('FF$hex', radix: 16));
        await addCustomColor(color, name.isEmpty ? '#$hex' : name);
      } else {
        throw FormatException('无效的十六进制颜色格式');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 通过RGB值添加颜色
  Future<void> addCustomColorFromRGB(int r, int g, int b, String name) async {
    if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
      throw RangeError('RGB值必须在0-255之间');
    }
    
    final color = Color.fromRGBO(r, g, b, 1.0);
    final colorName = name.isEmpty ? 'RGB($r,$g,$b)' : name;
    await addCustomColor(color, colorName);
  }

  /// 删除自定义颜色
  Future<void> removeCustomColor(Color color) async {
    _customColors.removeWhere((c) => c.color.value == color.value);
    await _saveSettings();
    notifyListeners();
  }

  /// 清除所有自定义颜色
  Future<void> clearCustomColors() async {
    _customColors.clear();
    await _saveSettings();
    notifyListeners();
  }

  /// 根据主题模式字符串获取对应的ThemeMode枚举
  ThemeMode getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 生成亮色主题配置
  ThemeData generateLightTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: seedColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  /// 生成暗色主题配置
  ThemeData generateDarkTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: seedColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}