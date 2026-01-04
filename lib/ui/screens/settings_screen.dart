import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';
import 'package:miao3trikeflutter/ui/widgets/macro_settings_dialog.dart';
import 'package:miao3trikeflutter/ui/screens/theme_setting_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 随机数生成器
  final Random _random = Random();
  
  // 显示随机消息
  void _showRandomMessage(BuildContext context, ThemeManager themeManager) {
    // 90%概率显示第一条消息，10%概率显示第二条
    final randomValue = _random.nextDouble();
    final message = randomValue < 0.9 
        ? '喵呜~不要戳(˃̶͈̀௰˂̶͈́)'
        : '愿毛茸茸治愈你的一天~';
    
    // 显示SnackBar提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: themeManager.seedColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /*void _showResetConfirmation(BuildContext context, ThemeManager themeManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text(
          '这将恢复所有设置为默认值，包括宏配置和用户偏好设置。此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final appState = context.read<AppState>();
              appState.resetMacroConfig();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('所有设置已重置为默认值'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: themeManager.seedColor,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final seedColor = themeManager.seedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 根据介绍页面的配色方案生成颜色变体
    final lightVariant = isDark ? seedColor.withValues(alpha: 0.8) : seedColor.withValues(alpha: 0.1);
    final mediumVariant = isDark ? seedColor.withValues(alpha: 0.6) : seedColor.withValues(alpha: 0.3);
    final darkVariant = isDark ? seedColor.withValues(alpha: 0.9) : seedColor.withValues(alpha: 0.7);
    //final buttonVariant = isDark ? seedColor.withValues(alpha: 0.5) : seedColor;
    final subtleColor = isDark ? Colors.grey[400]! : Colors.grey.shade600;
    final cardBackground = isDark ? Colors.grey[900]! : Colors.white;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 64),
            // 设置标题
            Text(
              '设置',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '配置应用参数和查看相关信息',
              style: TextStyle(
                color: subtleColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),

            /*// 宏设置卡片
            Card(
              elevation: 3,
              color: cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: darkVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '宏设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '调整宏操作的延迟参数和功能开关',
                      style: TextStyle(
                        color: subtleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const MacroSettingsDialog(),
                        ).then((_) {
                          // 使用mounted检查确保widget仍然存在
                          if (mounted) {
                            final appState = context.read<AppState>();
                            appState.refreshAll();
                          }
                        });
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('打开宏设置'),
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonVariant,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),*/

            // 其他设置
            Card(
              elevation: 3,
              color: cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_suggest,
                          color: darkVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '应用设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 添加宏设置入口
                    ListTile(
                      leading: Icon(
                        Icons.timer_outlined,
                        color: darkVariant,
                      ),
                      title: Text(
                        '宏设置',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '调整宏操作的延迟参数和功能开关',
                        style: TextStyle(
                          color: subtleColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: subtleColor,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const MacroSettingsDialog(),
                        ).then((_) {
                          // 使用mounted检查确保widget仍然存在
                          if (mounted) {
                            final appState = context.read<AppState>();
                            appState.refreshAll();
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    // 添加主题设置入口
                    ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: darkVariant,
                      ),
                      title: Text(
                        '主题设置',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '切换主题明暗与配色',
                        style: TextStyle(
                          color: subtleColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: subtleColor,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ThemeSettingScreen(),
                          ),
                        );
                      },
                    ),
                    /*const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.restart_alt,
                        color: darkVariant,
                      ),
                      title: Text(
                        '重置所有设置',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '恢复所有设置为默认值',
                        style: TextStyle(
                          color: subtleColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.restore,
                          color: darkVariant,
                        ),
                        onPressed: () {
                          _showResetConfirmation(context, themeManager);
                        },
                      ),
                    ),*/
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 关于作者卡片
            Card(
              elevation: 3,
              color: cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: darkVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '关于作者',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 原作作者
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.cyan,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '原作作者',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bilibili: 猫十五喵喵',
                                  style: TextStyle(
                                    color: subtleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openUrl(
                                'https://space.bilibili.com/506666307'),
                            icon: Icon(
                              Icons.open_in_new,
                              color: Colors.cyan,
                            ),
                            tooltip: '打开作者主页',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 魔改作者
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.lightGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.lightGreen,
                            child: const Icon(
                              Icons.auto_fix_high,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '魔改作者',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bilibili: TheEternal',
                                  style: TextStyle(
                                    color: subtleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openUrl(
                                'https://space.bilibili.com/8613786'),
                            icon: Icon(
                              Icons.open_in_new,
                              color: Colors.lightGreen,
                            ),
                            tooltip: '打开作者主页',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // FlutterUI作者
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.code,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FlutterUI套壳',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bilibili: 域空Hollow',
                                  style: TextStyle(
                                    color: subtleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openUrl(
                                'https://space.bilibili.com/1572457623'),
                            icon: Icon(
                              Icons.open_in_new,
                              color: Colors.blue,
                            ),
                            tooltip: '打开作者主页',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 彩蛋
                    GestureDetector(
                      onTap: () => _showRandomMessage(context, themeManager),
                      child: Container(
                        width: double.infinity,
                        height: 320,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: mediumVariant,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'images/img_anime_char.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 如果图片加载失败，显示备用图标和提示
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      lightVariant,
                                      mediumVariant,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_emotions,
                                      size: 60,
                                      color: darkVariant,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '点击有惊喜哦~',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: darkVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 开源协议
            Card(
              elevation: 3,
              color: cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开源协议：MIT License',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '本应用基于开源项目开发，遵循相关开源协议。',
                      style: TextStyle(
                        color: subtleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ActionChip(
                          label: const Text('GitHub'),
                          avatar: Icon(Icons.code, size: 18, color: darkVariant),
                          onPressed: () {
                            _openUrl('https://github.com/Hollow-YK/Miao3trike_Flutter');
                          },
                        ),
                        ActionChip(
                          label: const Text('Miao3trike'),
                          avatar: Icon(Icons.code, size: 18, color: darkVariant),
                          onPressed: () {
                            _openUrl('https://github.com/SuperMaxine/Miao3trikeMod');
                          },
                        ),
                        ActionChip(
                          label: const Text('Miao3trikeMod'),
                          avatar: Icon(Icons.code, size: 18, color: darkVariant),
                          onPressed: () {
                            _openUrl('https://github.com/ESHIWU/Miao3trike');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 版本信息
            Center(
              child: Column(
                children: [
                  Text(
                    'Miao3trike Flutter',
                    style: TextStyle(
                      color: subtleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '感谢作者们！',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}