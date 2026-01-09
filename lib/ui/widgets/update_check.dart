import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// 本地版本常量
const String LOCAL_VERSION = "1.0.3";
const String LOCAL_VERSION_CODE = "6";
const String LOCAL_CORE_VERSION_CODE = "2";
const bool IS_BETA = false;

class VersionInfo {
  final String version;
  final String versionCode;
  final String changelog;

  VersionInfo({
    required this.version,
    required this.versionCode,
    required this.changelog,
  });
}

class RemoteVersionData {
  final VersionInfo release;
  final VersionInfo beta;
  final VersionInfo core;

  RemoteVersionData({
    required this.release,
    required this.beta,
    required this.core,
  });

  factory RemoteVersionData.fromJson(Map<String, dynamic> json) {
    return RemoteVersionData(
      release: VersionInfo(
        version: json['release']['version'] ?? '',
        versionCode: json['release']['versioncode'] ?? '0',
        changelog: json['release']['changelog'] ?? '',
      ),
      beta: VersionInfo(
        version: json['beta']['version'] ?? '',
        versionCode: json['beta']['versioncode'] ?? '0',
        changelog: json['beta']['changelog'] ?? '',
      ),
      core: VersionInfo(
        version: json['core']['version'] ?? '',
        versionCode: json['core']['versioncode'] ?? '0',
        changelog: '',
      ),
    );
  }
}

class UpdateCheckerDialog extends StatefulWidget {
  const UpdateCheckerDialog({Key? key}) : super(key: key);

  @override
  _UpdateCheckerDialogState createState() => _UpdateCheckerDialogState();
}

class _UpdateCheckerDialogState extends State<UpdateCheckerDialog> {
  RemoteVersionData? _remoteData;
  bool _isLoading = true;
  String? _error;
  HttpClient? _httpClient;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // 取消正在进行的网络请求
    _httpClient?.close(force: true);
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    // 如果已经销毁，不执行任何操作
    if (_isDisposed) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _httpClient = HttpClient();
      // 设置连接超时和空闲超时
      _httpClient!.connectionTimeout = const Duration(seconds: 10);
      
      final request = await _httpClient!.getUrl(
        IS_BETA ? Uri.parse('https://raw.githubusercontent.com/Hollow-YK/Miao3trike_Flutter/Dev/version.json')
                 : Uri.parse('https://raw.githubusercontent.com/Hollow-YK/Miao3trike_Flutter/main/version.json'),
      );
      
      // 使用 Future.timeout 包装整个请求
      final response = await request.close().timeout(const Duration(seconds: 15));
      
      // 再次检查是否还挂载
      if (!mounted || _isDisposed) return;
      
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final jsonData = json.decode(content);
        
        // 检查是否还挂载
        if (!mounted || _isDisposed) return;
        
        setState(() {
          _remoteData = RemoteVersionData.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        // 检查是否还挂载
        if (!mounted || _isDisposed) return;
        
        setState(() {
          _error = '获取版本信息失败: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on SocketException catch (e) {
      // 网络连接错误
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _error = '网络连接失败: ${e.message}';
        _isLoading = false;
      });
    } on HttpException catch (e) {
      // HTTP错误
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _error = 'HTTP请求失败: ${e.message}';
        _isLoading = false;
      });
    } on FormatException catch (e) {
      // JSON解析错误
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _error = '数据格式错误: ${e.message}';
        _isLoading = false;
      });
    } on TimeoutException catch (_) {
      // 超时错误
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _error = '请求超时，请检查网络连接';
        _isLoading = false;
      });
    } catch (e) {
      // 其他错误
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _error = '发生未知错误: $e';
        _isLoading = false;
      });
    } finally {
      // 清理 HttpClient
      _httpClient?.close();
    }
  }

  void _openGitHubRelease() async {
    const url = 'https://github.com/Hollow-YK/Miao3trike_Flutter/releases';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _getReleaseStatus() {
    if (_remoteData == null) return '';
    
    final localCode = int.tryParse(LOCAL_VERSION_CODE) ?? 0;
    final remoteReleaseCode = int.tryParse(_remoteData!.release.versionCode) ?? 0;
    
    if (localCode < remoteReleaseCode) {
      return 'new_version';
    } else if (localCode == remoteReleaseCode) {
      return 'latest';
    } else {
      return IS_BETA ? 'beta_version' : 'future_version';
    }
  }

  String _getBetaStatus() {
    if (_remoteData == null || !IS_BETA) return '';
    
    final localCode = int.tryParse(LOCAL_VERSION_CODE) ?? 0;
    final remoteReleaseCode = int.tryParse(_remoteData!.release.versionCode) ?? 0;
    final remoteBetaCode = int.tryParse(_remoteData!.beta.versionCode) ?? 0;
    
    if (remoteBetaCode <= remoteReleaseCode) {
      return 'no_newer_beta';
    } else if (localCode < remoteBetaCode) {
      return 'new_beta';
    } else if (localCode == remoteBetaCode) {
      return 'latest_beta';
    } else {
      return 'custom_build';
    }
  }

  Widget _buildCoreUpdateWarning() {
    if (_remoteData == null) return const SizedBox();
    
    final localCoreCode = int.tryParse(LOCAL_CORE_VERSION_CODE) ?? 0;
    final remoteCoreCode = int.tryParse(_remoteData!.core.versionCode) ?? 0;
    
    if (localCoreCode < remoteCoreCode) {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[900]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '核心版本有更新！',
                style: TextStyle(
                  color: Colors.red[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildReleaseSection() {
    final status = _getReleaseStatus();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '正式版：',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (status == 'new_version' && _remoteData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('有新版本：${_remoteData!.release.version}(${_remoteData!.release.versionCode})'),
              const SizedBox(height: 8),
              Text(
                '更新日志：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _remoteData!.release.changelog,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          )
        else if (status == 'latest')
          Text('当前是最新版！', style: TextStyle(color: Colors.green[700]))
        else if (status == 'beta_version')
          Text('当前是测试版！', style: TextStyle(color: Colors.orange[700]))
        else if (status == 'future_version')
          Text(
            '你的版本是未来的，软件却相当古老。你究竟是什么版本？',
            style: TextStyle(color: Colors.purple[700]),
          ),
      ],
    );
  }

  Widget _buildBetaSection() {
    if (!IS_BETA) return const SizedBox();
    
    final status = _getBetaStatus();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '测试版：',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (status == 'new_beta' && _remoteData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('有新版本：${_remoteData!.beta.version}(${_remoteData!.beta.versionCode})'),
              const SizedBox(height: 8),
              Text(
                '更新日志：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _remoteData!.beta.changelog,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          )
        else if (status == 'no_newer_beta')
          Text(
            '当前没有比正式版更新的测试版！',
            style: TextStyle(color: Colors.blue[700]),
          )
        else if (status == 'latest_beta')
          Text('当前是最新版！', style: TextStyle(color: Colors.green[700]))
        else if (status == 'custom_build')
          Text('你是自己编译的？', style: TextStyle(color: Colors.orange[700])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('检查更新'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前版本信息
            Text(
              '当前版本：$LOCAL_VERSION ($LOCAL_VERSION_CODE) Core $LOCAL_CORE_VERSION_CODE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '错误：$_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _checkForUpdates,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              )
            else if (_remoteData != null) ...[
              // 核心版本更新警告
              _buildCoreUpdateWarning(),
              
              // 正式版信息
              _buildReleaseSection(),
              
              // 测试版信息（如果是测试版）
              _buildBetaSection(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
        if (_remoteData != null && 
            (_getReleaseStatus() == 'new_version' || 
             _getBetaStatus() == 'new_beta'))
          ElevatedButton(
            onPressed: _openGitHubRelease,
            child: const Text('前往GitHub Release'),
          ),
      ],
    );
  }
}

// 工具函数：显示更新检查对话框
void showUpdateCheckerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const UpdateCheckerDialog(),
  );
}

// 用于在设置页面中的按钮
class UpdateCheckerButton extends StatelessWidget {
  const UpdateCheckerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => showUpdateCheckerDialog(context),
      icon: const Icon(Icons.update),
      label: const Text('检查更新'),
    );
  }
}