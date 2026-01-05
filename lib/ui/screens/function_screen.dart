import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';
import 'package:miao3trikeflutter/ui/widgets/permission_card.dart';

class FunctionScreen extends StatefulWidget {
  const FunctionScreen({super.key});

  @override
  State<FunctionScreen> createState() => _FunctionScreenState();
}

class _FunctionScreenState extends State<FunctionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final seedColor = themeManager.seedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 根据亮度调整颜色变体
    final lightVariant = isDark ? seedColor.withValues(alpha: 0.8) : seedColor.withValues(alpha: 0.1);
    final mediumVariant = isDark ? seedColor.withValues(alpha: 0.6) : seedColor.withValues(alpha: 0.3);
    final darkVariant = isDark ? seedColor.withValues(alpha: 0.9) : seedColor.withValues(alpha: 0.7);
    final buttonVariant = isDark ? seedColor.withValues(alpha: 0.5) : seedColor;
    final subtleColor = isDark ? Colors.grey[400]! : Colors.grey.shade600;
    final cardBackground = isDark ? Colors.grey[900]! : Colors.white; 
    final surfaceVariant = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: seedColor),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72),
                // 设置标题
                Text(
                  '功能',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '查看功能与运行状态相关信息',
                  style: TextStyle(
                    color: subtleColor,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 64),

                // 控制卡片
                Card(
                  elevation: 3,
                  color: cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!state.isServiceRunning) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '请先启动悬浮窗服务以使用功能',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // 悬浮窗服务状态显示（移动到控制卡片顶端）
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '悬浮窗服务',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.isServiceRunning ? '服务运行中' : '服务已停止',
                                    style: TextStyle(
                                      color: subtleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isServiceRunning
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: state.isServiceRunning
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  state.isServiceRunning ? '运行中' : '已停止',
                                  style: TextStyle(
                                    color: state.isServiceRunning
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 服务控制按钮
                        FilledButton(
                          onPressed: () => state.toggleService(),
                          style: FilledButton.styleFrom(
                            backgroundColor: state.isServiceRunning
                                ? Colors.red
                                : buttonVariant,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                state.isServiceRunning
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                state.isServiceRunning
                                    ? '停止悬浮窗服务'
                                    : '启动悬浮窗服务',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 33),

                // 当前状态信息
                Card(
                  elevation: 3,
                  color: cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前状态',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          context,
                          '功能状态',
                          state.isFunctionEnabled ? '已启用' : '已禁用',
                          state.isFunctionEnabled ? Colors.green : Colors.grey,
                        ),
                        _buildStatusRow(
                          context,
                          '无障碍服务',
                          state.isAccessibilityEnabled ? '已授权' : '未授权',
                          state.isAccessibilityEnabled
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _buildStatusRow(
                          context,
                          '悬浮窗权限',
                          state.isOverlayPermissionGranted ? '已授权' : '未授权',
                          state.isOverlayPermissionGranted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // 权限状态卡片
                PermissionCard(
                  isAccessibilityEnabled: state.isAccessibilityEnabled,
                  isOverlayPermissionGranted: state.isOverlayPermissionGranted,
                  onRefresh: () => state.refreshAll(),
                ),

                const SizedBox(height: 40),

                // 快捷操作提示 - 使用介绍页面的配色方案
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark ? [mediumVariant.withValues(alpha: 0.1),mediumVariant.withValues(alpha: 0.3),mediumVariant.withValues(alpha: 0.5),lightVariant,] : [lightVariant,lightVariant,lightVariant,lightVariant,mediumVariant,],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mediumVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: darkVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '快捷操作提示',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildShortcutItem(context, darkVariant, '音量 +',
                          '零帧选取\n暂停时按下后点击干员位置，松手后自动选取相应干员'),
                      _buildShortcutItem(context, darkVariant, '音量 -',
                          '逐帧步进\n暂停时点击即可逐帧前进，适用于精确操作'),
                      _buildShortcutItem(context, darkVariant, '悬浮球',
                          '划火柴\n太长了这里写不开，去介绍页面看吧（'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildShortcutItem(
      BuildContext context, Color primaryColor, String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              key,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}