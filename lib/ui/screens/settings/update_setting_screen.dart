import 'package:flutter/material.dart';
import 'package:miao3trikeflutter/core/services/update_manager.dart';

/// 渠道设置页面 - 允许用户设置更新渠道和GitHub镜像
class UpdateSettingScreen extends StatefulWidget {
  const UpdateSettingScreen({super.key});

  @override
  State<UpdateSettingScreen> createState() => _UpdateSettingScreenState();
}

/// 渠道设置页面的状态类
class _UpdateSettingScreenState extends State<UpdateSettingScreen> {
  // 用于镜像地址输入的控制器
  final TextEditingController _mirrorUrlController = TextEditingController();
  final FocusNode _mirrorUrlFocusNode = FocusNode();

  final UpdateManager _updateManager = UpdateManager();
  bool _useMirror = false;
  String _updateChannel = 'github';
  String _mirrorUrl = '';

  @override
  void initState() {
    super.initState();
    // 异步加载设置
    _loadSettings();
  }

  @override
  void dispose() {
    _mirrorUrlController.dispose();
    _mirrorUrlFocusNode.dispose();
    super.dispose();
  }

  /// 加载当前设置
  Future<void> _loadSettings() async {
    await _updateManager.init();

    if (mounted) {
      setState(() {
        _updateChannel = _updateManager.updateChannel;
        _useMirror = _updateManager.useMirror;
        _mirrorUrl = _updateManager.mirrorUrl;
        _mirrorUrlController.text = _mirrorUrl;
      });
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (mounted) {
      setState(() {
        _updateChannel = _updateManager.updateChannel;
        _useMirror = _updateManager.useMirror;
        _mirrorUrl = _updateManager.mirrorUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('渠道设置'),
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
            // Tips卡片
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildChannelInfoItem(
                      context,
                      title: 'GitHub',
                      description: '官方仓库，更新及时但国内访问可能较慢',
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 12),
                    _buildChannelInfoItem(
                      context,
                      title: 'Gitee',
                      description: '国内镜像，访问速度快但更新可能有延迟',
                      icon: Icons.speed,
                    ),
                    const SizedBox(height: 12),
                    _buildChannelInfoItem(
                      context,
                      title: 'GitHub，但是镜像',
                      description: '既要国内流畅访问，又要更新及时，那么为什么不试试选择GitHub源并启用镜像呢？',
                      icon: Icons.accessible_forward,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '提示：如果GitHub访问困难，可以试试切换至Gitee渠道或配置GitHub镜像',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 检查更新渠道标题
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                '检查更新渠道',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // 更新渠道设置卡片
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.update,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('更新渠道'),
                      subtitle: const Text('选择检查更新的数据源'),
                      trailing: DropdownButton<String>(
                        value: _updateChannel,
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            await _updateManager.setUpdateChannel(newValue);
                            await _saveSettings();
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'github',
                            child: Text('GitHub'),
                          ),
                          DropdownMenuItem(
                            value: 'gitee',
                            child: Text('Gitee'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // GitHub设置标题
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'GitHub设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // GitHub设置卡片
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用镜像开关
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用镜像'),
                      subtitle: const Text(
                        '启用后，将从镜像地址获取GitHub数据。只有在选择GitHub源时才会生效。',
                      ),
                      value: _useMirror,
                      onChanged: (bool value) async {
                        await _updateManager.setUseMirror(value);
                        await _saveSettings();
                      },
                    ),

                    const SizedBox(height: 16),

                    // 镜像地址输入（仅在使用镜像时显示）
                    if (_useMirror)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '镜像地址',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _mirrorUrlController,
                            focusNode: _mirrorUrlFocusNode,
                            decoration: InputDecoration(
                              labelText: '镜像URL地址',
                              border: const OutlineInputBorder(),
                              hintText: '例如: https://mirror.ghproxy.com/',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: _mirrorUrlController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _mirrorUrlController.clear();
                                        _updateManager.setMirrorUrl('');
                                        _saveSettings();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              _updateManager.setMirrorUrl(value);
                            },
                            onSubmitted: (value) async {
                              await _updateManager.setMirrorUrl(value);
                              await _saveSettings();
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '注意：请输入完整的镜像地址，如 https://mirror.ghproxy.com/ ，然后系统会自动将GitHub地址附加到后面。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '启用"使用镜像"开关以配置镜像地址',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 镜像状态和测试按钮
                    if (_useMirror && _mirrorUrl.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isValidUrl(_mirrorUrl)
                              ? Colors.green.withAlpha(25)
                              : Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isValidUrl(_mirrorUrl)
                                ? Colors.green.withAlpha(76)
                                : Colors.orange.withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isValidUrl(_mirrorUrl)
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: isValidUrl(_mirrorUrl)
                                  ? Colors.green
                                  : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isValidUrl(_mirrorUrl)
                                    ? '镜像地址格式正确'
                                    : '请输入有效的URL地址（以http://或https://开头）',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isValidUrl(_mirrorUrl)
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            if (isValidUrl(_mirrorUrl))
                              TextButton(
                                onPressed: () {
                                  _testMirrorConnection();
                                },
                                child: const Text('测试连接'),
                              ),
                          ],
                        ),
                      ),

                    // 常用镜像地址提示
                    if (_useMirror)
                      ExpansionTile(
                        title: const Text('镜像地址参考'),
                        initiallyExpanded: false,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withAlpha(51),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '下列内容来自于网络',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '感谢镜像的提供者。',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildMirrorExample(
                                  context,
                                  name: 'gh.llkk.cc',
                                  url: 'https://gh.llkk.cc/',
                                  description: '网上找的',
                                ),
                                const SizedBox(height: 8),
                                _buildMirrorExample(
                                  context,
                                  name: 'ghproxy',
                                  url: 'https://ghproxy.net/',
                                  description: '应该能用',
                                ),
                                const SizedBox(height: 8),
                                _buildMirrorExample(
                                  context,
                                  name: 'gitproxy.click',
                                  url: 'https://gitproxy.click/',
                                  description: '能用吧',
                                ),
                                const SizedBox(height: 8),
                                _buildMirrorExample(
                                  context,
                                  name: 'gh-proxy',
                                  url: 'https://gh-proxy.top',
                                  description: '我寻思能用',
                                ),
                              ],
                            ),
                          ),
                        ],
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

  /// 构建镜像地址示例项
  Widget _buildMirrorExample(
    BuildContext context, {
    required String name,
    required String url,
    required String description,
  }) {
    return InkWell(
      onTap: () async {
        _mirrorUrlController.text = url;
        await _updateManager.setMirrorUrl(url);
        await _saveSettings();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.content_copy,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              url,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建渠道信息项
  Widget _buildChannelInfoItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 测试镜像连接
  Future<void> _testMirrorConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在测试镜像连接...'),
        duration: Duration(seconds: 2),
      ),
    );

    // 模拟网络测试
    await Future.delayed(const Duration(seconds: 1));

    final success = await _updateManager.testMirrorConnection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '镜像连接成功' : '镜像连接失败，请检查地址'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
