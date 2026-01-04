import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';

/// 主题设置页面 - 允许用户自定义应用的主题和颜色
class ThemeSettingScreen extends StatefulWidget {
  const ThemeSettingScreen({super.key});

  @override
  State<ThemeSettingScreen> createState() => _ThemeSettingScreenState();
}

/// 主题设置页面的状态类
class _ThemeSettingScreenState extends State<ThemeSettingScreen> {
  final TextEditingController _colorNameController = TextEditingController();

  /// 显示自定义颜色对话框
  void _showCustomColorDialog(BuildContext context, ThemeManager themeManager) {
    Color selectedColor = themeManager.seedColor;
    _colorNameController.text = '自定义颜色';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义颜色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 颜色选择器
              SizedBox(
                height: 200,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 36,
                  itemBuilder: (context, index) {
                    // 生成颜色网格
                    final hue = (index * 10) % 360;
                    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor();
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedColor.value == color.value
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 自定义颜色名称
              TextField(
                controller: _colorNameController,
                decoration: const InputDecoration(
                  labelText: '颜色名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              // 颜色预览
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                alignment: Alignment.center,
                child: Text(
                  '预览: ${selectedColor.value.toRadixString(16).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (_colorNameController.text.trim().isNotEmpty) {
                themeManager.addCustomColor(
                  selectedColor,
                  _colorNameController.text.trim(),
                );
                themeManager.setSeedColor(selectedColor);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('自定义颜色已保存并应用'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('保存并应用'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _colorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 明暗设置项标题
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                '明暗设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // 明暗设置卡片
            Card(
              elevation: 3,
              child: Column(
                children: [
                  _buildThemeModeItem(
                    themeManager,
                    icon: Icons.brightness_auto,
                    title: '跟随系统',
                    value: 'system',
                  ),
                  const Divider(height: 1),
                  _buildThemeModeItem(
                    themeManager,
                    icon: Icons.light_mode,
                    title: '浅色模式',
                    value: 'light',
                  ),
                  const Divider(height: 1),
                  _buildThemeModeItem(
                    themeManager,
                    icon: Icons.dark_mode,
                    title: '深色模式',
                    value: 'dark',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 主题颜色标题和添加按钮
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '主题颜色',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCustomColorDialog(context, themeManager),
                  tooltip: '添加自定义颜色',
                ),
              ],
            ),
            
            // 预定义颜色卡片
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '预定义颜色',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorGrid(themeManager, themeManager.predefinedColors),
                  ],
                ),
              ),
            ),
            
            // 自定义颜色卡片
            if (themeManager.customColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '自定义颜色',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认清空'),
                                  content: const Text('确定要清空所有自定义颜色吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        themeManager.clearCustomColors();
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('已清空自定义颜色'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Text('确认'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: '清空自定义颜色',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildColorGrid(themeManager, themeManager.customColors, isCustom: true),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 预览卡片
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '预览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前主题预览',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: themeManager.seedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '主题色：${_getColorName(themeManager)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getCurrentThemeModeName(themeManager),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            themeManager.themeMode == 'dark'
                                ? Icons.dark_mode
                                : themeManager.themeMode == 'light'
                                    ? Icons.light_mode
                                    : Icons.brightness_auto,
                            color: themeManager.seedColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建颜色选项网格布局
  Widget _buildColorGrid(ThemeManager themeManager, List<ColorOption> colors, {bool isCustom = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorOption = colors[index];
        return _buildColorOption(themeManager, colorOption, isCustom: isCustom);
      },
    );
  }

  /// 构建主题模式选项项
  Widget _buildThemeModeItem(
    ThemeManager themeManager, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isSelected = themeManager.themeMode == value;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        themeManager.setThemeMode(value);
      },
    );
  }

  /// 构建颜色选项
  Widget _buildColorOption(ThemeManager themeManager, ColorOption colorOption, {bool isCustom = false}) {
    final isSelected = colorOption.color.value == themeManager.seedColor.value;
    
    return GestureDetector(
      onTap: () {
        themeManager.setSeedColor(colorOption.color);
      },
      onLongPress: isCustom ? () {
        _showDeleteDialog(context, themeManager, colorOption);
      } : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色圆圈
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorOption.color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: _getContrastColor(colorOption.color),
                      width: 3,
                    )
                  : Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      width: 1,
                    ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: colorOption.color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _getContrastColor(colorOption.color),
                    size: 24,
                  )
                : isCustom
                    ? Icon(
                        Icons.edit_outlined,
                        color: _getContrastColor(colorOption.color),
                        size: 20,
                      )
                    : null,
          ),
          const SizedBox(height: 6),
          // 颜色名称
          Text(
            colorOption.name,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(BuildContext context, ThemeManager themeManager, ColorOption colorOption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除颜色'),
        content: Text('确定要删除自定义颜色 "${colorOption.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              themeManager.removeCustomColor(colorOption.color);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除颜色: ${colorOption.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 获取与给定颜色形成对比的颜色
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 获取当前主题模式的显示名称
  String _getCurrentThemeModeName(ThemeManager themeManager) {
    switch (themeManager.themeMode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      case 'system':
      default:
        return '跟随系统';
    }
  }

  /// 获取颜色名称
  String _getColorName(ThemeManager themeManager) {
    final allColors = themeManager.allColors;
    final currentColor = themeManager.seedColor;
    final colorOption = allColors.firstWhere(
      (c) => c.color.value == currentColor.value,
      orElse: () => const ColorOption(color: Colors.grey, name: '自定义'),
    );
    return colorOption.name;
  }
}