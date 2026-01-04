import 'package:flutter/material.dart';
import 'package:miao3trikeflutter/core/native_bridge.dart';

class PermissionCard extends StatelessWidget {
  final bool isAccessibilityEnabled;
  final bool isOverlayPermissionGranted;
  //final bool isServiceRunning;
  final VoidCallback onRefresh;

  const PermissionCard({
    super.key,
    required this.isAccessibilityEnabled,
    required this.isOverlayPermissionGranted,
    //required this.isServiceRunning,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '权限管理',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: '刷新状态',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              '无障碍服务',
              '用于监听音量键和执行手势',
              isAccessibilityEnabled,
              () => NativeBridge.requestAccessibilityPermission(),
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              '悬浮窗权限',
              '用于显示悬浮控制按钮',
              isOverlayPermissionGranted,
              () => NativeBridge.requestOverlayPermission(),
            ),
            /*onst SizedBox(height: 12),
            _buildStatusItem(
              '悬浮窗服务',
              isServiceRunning,
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, bool enabled, VoidCallback onRequest) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        enabled ? Icons.check_circle : Icons.error,
        color: enabled ? Colors.green : Colors.orange,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(description),
      trailing: !enabled
          ? FilledButton.tonal(
              onPressed: onRequest,
              child: const Text('去开启'),
            )
          : null,
    );
  }

  /*Widget _buildStatusItem(String title, bool running) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        running ? Icons.check_circle : Icons.pending,
        color: running ? Colors.green : Colors.grey,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(running ? '运行中' : '未运行'),
    );
  }*/
}