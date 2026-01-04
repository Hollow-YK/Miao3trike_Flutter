import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/core/services/app_state.dart';

class MacroSettingsDialog extends StatefulWidget {
  const MacroSettingsDialog({super.key});

  @override
  State<MacroSettingsDialog> createState() => _MacroSettingsDialogState();
}

class _MacroSettingsDialogState extends State<MacroSettingsDialog> {
  late Map<String, dynamic> _config;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _config = Map.from(state.macroConfig);
    
    // 初始化控制器
    _controllers['startupDelayMs'] = TextEditingController(text: _config['startupDelayMs'].toString());
    _controllers['stepDelayMs'] = TextEditingController(text: _config['stepDelayMs'].toString());
    _controllers['dragDurationMs'] = TextEditingController(text: _config['dragDurationMs'].toString());
    _controllers['holdDelayMs'] = TextEditingController(text: _config['holdDelayMs'].toString());
    _controllers['stepMacroDelayMs'] = TextEditingController(text: _config['stepMacroDelayMs'].toString());
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _saveConfig() {
    final state = context.read<AppState>();
    
    // 更新配置
    final newConfig = Map<String, dynamic>.from(_config);
    for (var key in _controllers.keys) {
      final value = int.tryParse(_controllers[key]!.text) ?? 0;
      newConfig[key] = value;
    }
    
    state.updateMacroConfig(newConfig);
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    context.read<AppState>().resetMacroConfig();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('宏设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 启动延迟
            _buildNumberField(
              label: '启动延迟 (ms)',
              hint: '宏开始的延迟时间',
              controller: _controllers['startupDelayMs']!,
              min: 0,
              max: 5000,
            ),
            const SizedBox(height: 12),
            
            // 步骤延迟
            _buildNumberField(
              label: '步骤延迟 (ms)',
              hint: '每个步骤之间的延迟',
              controller: _controllers['stepDelayMs']!,
              min: 0,
              max: 1000,
            ),
            const SizedBox(height: 12),
            
            // 拖动时长
            _buildNumberField(
              label: '拖动时长 (ms)',
              hint: '拖动动作的持续时间',
              controller: _controllers['dragDurationMs']!,
              min: 0,
              max: 5000,
            ),
            const SizedBox(height: 12),
            
            // 保持延迟
            _buildNumberField(
              label: '保持延迟 (ms)',
              hint: '动作结束后的保持时间',
              controller: _controllers['holdDelayMs']!,
              min: 0,
              max: 5000,
            ),
            const SizedBox(height: 12),
            
            // 步进宏延迟
            _buildNumberField(
              label: '步进宏延迟 (ms)',
              hint: '步进宏的延迟时间',
              controller: _controllers['stepMacroDelayMs']!,
              min: 0,
              max: 5000,
            ),
            const SizedBox(height: 16),
            
            // 功能开关
            SwitchListTile(
              title: const Text('点击捕获功能'),
              subtitle: const Text('启用音量+键点击捕获'),
              value: _config['clickCaptureEnabled'] ?? true,
              onChanged: (value) {
                setState(() {
                  _config['clickCaptureEnabled'] = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('步进宏功能'),
              subtitle: const Text('启用音量-键步进宏'),
              value: _config['stepMacroEnabled'] ?? true,
              onChanged: (value) {
                setState(() {
                  _config['stepMacroEnabled'] = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('恢复默认'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saveConfig,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required int min,
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixText: 'ms',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入数值';
        final intValue = int.tryParse(value);
        if (intValue == null) return '请输入有效数字';
        if (intValue < min || intValue > max) return '范围: $min-$max ms';
        return null;
      },
    );
  }
}