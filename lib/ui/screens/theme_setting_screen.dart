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
  // 用于颜色输入的局部状态
  bool _isHexInputMode = true;
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rController = TextEditingController();
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _inputNameController = TextEditingController();
  final FocusNode _hexFocusNode = FocusNode();
  final FocusNode _rFocusNode = FocusNode();
  final FocusNode _gFocusNode = FocusNode();
  final FocusNode _bFocusNode = FocusNode();

  /// 处理颜色添加
  void _handleAddColor(BuildContext context, ThemeManager themeManager) {
    final colorName = _inputNameController.text.trim();
    
    try {
      if (_isHexInputMode) {
        final hexValue = _hexController.text.trim();
        if (hexValue.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请输入十六进制颜色值'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // 清理十六进制字符串
        String hex = hexValue.replaceAll('#', '').toUpperCase();
        
        // 处理3位简写格式（如 #FFF）
        if (hex.length == 3) {
          hex = hex.split('').map((c) => c + c).join();
        }
        
        // 确保是6位十六进制数
        if (hex.length == 6) {
          final color = Color(int.parse('FF$hex', radix: 16));
          final name = colorName.isEmpty ? '#$hex' : colorName;
          
          themeManager.addCustomColor(color, name);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已添加颜色 $name'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 清空输入
          _hexController.clear();
          _inputNameController.clear();
          
          // 切换焦点
          _hexFocusNode.requestFocus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请输入6位十六进制颜色值（如 FF5733）'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      } else {
        final rText = _rController.text.trim();
        final gText = _gController.text.trim();
        final bText = _bController.text.trim();
        
        if (rText.isEmpty || gText.isEmpty || bText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请输入完整的RGB值'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final r = int.parse(rText);
        final g = int.parse(gText);
        final b = int.parse(bText);
        
        // 验证范围
        if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RGB值必须在0-255之间'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final color = Color.fromRGBO(r, g, b, 1.0);
        final displayName = colorName.isEmpty ? 'RGB($r,$g,$b)' : colorName;
        
        themeManager.addCustomColor(color, displayName);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加颜色 $displayName'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 清空输入
        _rController.clear();
        _gController.clear();
        _bController.clear();
        _inputNameController.clear();
        
        // 切换焦点
        _rFocusNode.requestFocus();
      }
      
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('格式错误：请输入有效的数值'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    _inputNameController.dispose();
    _hexFocusNode.dispose();
    _rFocusNode.dispose();
    _gFocusNode.dispose();
    _bFocusNode.dispose();
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
            
            // 主题颜色标题
            Padding(
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
                    const SizedBox(height: 16),
                    
                    // 颜色输入区域
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '添加自定义颜色',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 颜色名称输入
                          TextField(
                            controller: _inputNameController,
                            decoration: const InputDecoration(
                              labelText: '颜色名称（可选）',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                              hintText: '留空将自动生成名称',
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 输入模式切换按钮
                          Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment<bool>(
                                      value: true,
                                      label: Text('十六进制'),
                                      icon: Icon(Icons.tag),
                                    ),
                                    ButtonSegment<bool>(
                                      value: false,
                                      label: Text('RGB'),
                                      icon: Icon(Icons.format_color_fill),
                                    ),
                                  ],
                                  selected: {_isHexInputMode},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    setState(() {
                                      _isHexInputMode = newSelection.first;
                                      // 切换焦点
                                      if (_isHexInputMode) {
                                        _hexFocusNode.requestFocus();
                                      } else {
                                        _rFocusNode.requestFocus();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 颜色值输入区域
                          if (_isHexInputMode)
                            TextField(
                              controller: _hexController,
                              focusNode: _hexFocusNode,
                              decoration: const InputDecoration(
                                labelText: '十六进制颜色值',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                                hintText: 'FF5733 或 #FF5733',
                                prefixText: '#',
                              ),
                              maxLength: 7,
                              onChanged: (value) {
                                // 转换为大写
                                if (value.isNotEmpty) {
                                  _hexController.text = value.toUpperCase();
                                  _hexController.selection = TextSelection.collapsed(offset: _hexController.text.length);
                                }
                              },
                              onSubmitted: (_) {
                                _handleAddColor(context, themeManager);
                              },
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _rController,
                                    focusNode: _rFocusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'R',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.circle, color: Colors.red, size: 16),
                                      hintText: '0-255',
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 3,
                                    onSubmitted: (_) {
                                      _gFocusNode.requestFocus();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _gController,
                                    focusNode: _gFocusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'G',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.circle, color: Colors.green, size: 16),
                                      hintText: '0-255',
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 3,
                                    onSubmitted: (_) {
                                      _bFocusNode.requestFocus();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _bController,
                                    focusNode: _bFocusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'B',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.circle, color: Colors.blue, size: 16),
                                      hintText: '0-255',
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 3,
                                    onSubmitted: (_) {
                                      _handleAddColor(context, themeManager);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // 添加按钮
                          Row(
                            children: [
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () {
                                  _handleAddColor(context, themeManager);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('添加颜色'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 自定义颜色网格
                    if (themeManager.customColors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildColorGrid(themeManager, themeManager.customColors, isCustom: true),
                    ],
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
}