import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';
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
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const SizedBox(height: 20),

                // 快捷操作提示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.cyan.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: Colors.cyan.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '快捷操作提示',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildShortcutItem(
                        '音量 +',
                        '零帧选取\n暂停时按下后点击干员位置，松手后自动选取相应干员',
                      ),
                      _buildShortcutItem(
                        '音量 -',
                        '逐帧步进\n暂停时点击即可逐帧前进，适用于精确操作',
                      ),
                      _buildShortcutItem(
                        '悬浮球',
                        '划火柴\n太长了这里写不开，去介绍页面看吧（',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 当前状态信息
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '当前状态',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          '功能状态',
                          state.isFunctionEnabled ? '已启用' : '已禁用',
                          state.isFunctionEnabled ? Colors.green : Colors.grey,
                        ),
                        _buildStatusRow(
                          '服务状态',
                          state.isServiceRunning ? '运行中' : '已停止',
                          state.isServiceRunning ? Colors.green : Colors.red,
                        ),
                        _buildStatusRow(
                          '无障碍服务',
                          state.isAccessibilityEnabled ? '已授权' : '未授权',
                          state.isAccessibilityEnabled
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _buildStatusRow(
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
                  isServiceRunning: state.isServiceRunning,
                  onRefresh: () => state.refreshAll(),
                ),

                const SizedBox(height: 20),

                // 控制卡片
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 功能开关
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '宏功能开关',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.isFunctionEnabled
                                        ? '已启用 - 音量键可触发宏'
                                        : '已禁用',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: state.isFunctionEnabled,
                                onChanged: (value) => state.toggleFunction(),
                                activeColor: Colors.cyan,
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
                                : const Color(0xFF00BCD4),
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

                        if (!state.isServiceRunning) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '请先启动悬浮窗服务以使用功能',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
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
      ),
    );
  }

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyan.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Color(0xFF00BCD4),
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
                color: Colors.grey.shade700,
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