import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miao3trikeflutter/core/services/theme_manager.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final seedColor = themeManager.seedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 根据亮度调整颜色变体
    final lightVariant = isDark ? seedColor.withValues(alpha: 0.8) : seedColor.withValues(alpha: 0.1);
    final mediumVariant = isDark ? seedColor.withValues(alpha: 0.6) : seedColor.withValues(alpha: 0.3);
    final darkVariant = isDark ? seedColor.withValues(alpha: 0.9) : seedColor.withValues(alpha: 0.7);
    final cardBackground = isDark ? Colors.grey[900]! : Colors.white;
    final infoBackground = isDark ? Colors.blueGrey[800]! : Colors.blue.shade50;
    final infoBorder = isDark ? Colors.blueGrey[600]! : Colors.blue.shade100;
    final warningBackground = isDark ? Colors.blueGrey[900]! : Colors.blue.shade50;
    final warningBorder = isDark ? Colors.blueGrey[700]! : Colors.blue.shade100;
    final textColor = isDark ? Colors.grey[300]! : Colors.grey.shade800;
    final subtleTextColor = isDark ? Colors.grey[400]! : Colors.grey.shade600;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 128),
            Center(
              child: Column(
                children: [
                  // 外发光效果容器
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lightVariant,
                          mediumVariant,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: seedColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(65),
                        child: Image.asset(
                          'images/icon.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    seedColor,
                                    Color.alphaBlend(seedColor.withOpacity(0.6), Colors.white),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(65),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // 应用名称
                  Text(
                    'Miao3trikeFlutter',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: seedColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 应用描述
                  Text(
                    '明日方舟划火柴小工具',
                    style: TextStyle(
                      fontSize: 18,
                      color: subtleTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // UI版本标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          seedColor.withOpacity(0.2),
                          seedColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seedColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: seedColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Flutter UI • ',
                          style: TextStyle(
                            color: seedColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'V1.0.1',
                          style: TextStyle(
                            color: darkVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Core 版本标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          seedColor.withOpacity(0.2),
                          seedColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seedColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Core • ',
                          style: TextStyle(
                            color: seedColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Miao3trikeMod V1.2',
                          style: TextStyle(
                            color: darkVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 简短介绍
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Text(
                      '基于Miao3trikeMod修改而来，\n使用Flutter提供Material Design风格的UI。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subtleTextColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 功能介绍部分
            Text(
              '功能介绍',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              icon: Icons.touch_app,
              title: '手势录制与回放',
              description: '在游戏暂停状态下点击悬浮开关，开启划火柴操作录制，此时拖动干员并不会真的拖动干员，而是绘制一条拖放路径，松手后，应用会自动播放"点暂停→拖出干员→手机返回键"的宏操作，放置到位后之后需要自行调整干员朝向。\n第一次使用务必校准暂停按钮位置！（点击悬浮开关，将出现的蓝色按钮拖动到游戏中暂停按钮的真实位置，一次设置，永久生效）',
              seedColor: seedColor,
              cardBackground: cardBackground,
            ),

            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              icon: Icons.timer,
              title: '精确时间控制',
              description: '零帧撤退与放技能：在游戏暂停状态下按下手机的**音量+**按键，开启干员位置录制，此时点击干员位置，松手后，应用会自动播放"点暂停→点击干员→点暂停"的宏脚本，然后可以自己选择开干员技能或是撤退。\n逐帧步进：在游戏暂停状态下按下手机的"音量-"按键，应用会自动播放"点暂停→等待→点暂停"的宏脚本，通过调整等待时间（"步进延迟"），可以以人类难以精确捕捉的时间逐帧步进游戏内时间，方便精细操作。',
              seedColor: seedColor,
              cardBackground: cardBackground,
            ),

            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              icon: Icons.accessibility_new,
              title: '无障碍服务',
              description: '通过Android无障碍服务监听音量键操作，实现游戏中的快捷功能触发。',
              seedColor: seedColor,
              cardBackground: cardBackground,
            ),

            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              icon: Icons.flip_to_front,
              title: '悬浮窗控制',
              description: '可拖动的悬浮控制按钮，方便快速开启/关闭功能，不干扰游戏界面。',
              seedColor: seedColor,
              cardBackground: cardBackground,
            ),

            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              icon: Icons.settings,
              title: '高度可配置',
              description: '支持毫秒级延迟设置，可调整启动延迟、步骤延迟、拖动时长等参数，适应不同设备需求。\n提供详细的配置选项，包括宏设置、功能开关、权限管理等，满足个性化需求。',
              seedColor: seedColor,
              cardBackground: cardBackground,
            ),

            const SizedBox(height: 40),

            // 使用说明
            Text(
              '使用说明',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: infoBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: infoBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepItem(
                    context: context,
                    number: '1',
                    title: '开启无障碍服务',
                    description: '在系统设置中开启Miao3trikeMod的无障碍权限',
                    seedColor: seedColor,
                  ),
                  _buildStepItem(
                    context: context,
                    number: '2',
                    title: '授予悬浮窗权限',
                    description: '允许应用在其他应用上层显示',
                    seedColor: seedColor,
                  ),
                  _buildStepItem(
                    context: context,
                    number: '3',
                    title: '启动悬浮窗服务',
                    description: '点击功能页面的启动按钮',
                    seedColor: seedColor,
                  ),
                  _buildStepItem(
                    context: context,
                    number: '4',
                    title: '开启功能开关',
                    description: '激活音量键监听和宏功能',
                    seedColor: seedColor,
                  ),
                  _buildStepItem(
                    context: context,
                    number: '5',
                    title: '开始使用',
                    description: '在游戏中通过音量键触发录制或执行宏',
                    seedColor: seedColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 注意事项
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: seedColor),
                      const SizedBox(width: 8),
                      Text(
                        '常见问题',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: seedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Q：为什么一进去划火柴不成功反而还取消暂停了？\n'
                    '• 有可能是模拟暂停按钮的位置不对，在划火柴模式下，将蓝色的示意点拖动到游戏中的暂停按钮位置再试试。\n'
                    'Q：为什么干员落地位置不是我放置的位置？\n'
                    '• 因为干员拖动过程中地图会有倾斜效果，建议先选中干员将地图倾斜到位再录制拖放路径，从而避免自动操作时产生位置的干员落点偏移。\n'
                    'Q："启动延迟"是什么？\n'
                    '• （TLDR：随便加，不影响划火柴，只影响你等脚本划完火柴的速度，但过低容易不稳定）录制拖放路径靠插入虚拟图层实现对手指位置的监控，如果参数中的启动延迟设置过小，会导致第一次暂停点击到虚拟图层从而取消暂停失败。最终表现为，划火柴失败，干员没放出来，并且解除了暂停。启动时间是在宏开始执行前的等待时间，即还没有解出暂停，因此增加这个参数并不会增加游戏内流动的时间。\n'
                    'Q："每步操作之间的延迟"是什么\n'
                    '• 顾名思义，在划火柴"点暂停→拖出干员→手机返回键"每步操作之间的等待时间，同时也是零帧撤退与放技能"点暂停→点击干员→点暂停"每步操作之间的等待时间，一般0ms无问题，增加会增加操作时游戏内流过的时间。\n'
                    'Q："悬停延迟"是什么？\n'
                    '• （TLDR：同"启动延迟"，也可以随便加，但过低容易不稳定）明日方舟将干员放在格子上需要你按着干员在格子上悬停一会儿才能确认位置并下落，如果直接拖过去0帧松手干员是落不下的。这个时间在脚本恢复暂停后才会开始等待，因此增加这个参数也不会增加游戏内流动的时间。\n'
                    'Q："拖动速度"是什么？\n'
                    '• 是拖动干员到目标位置所需要的时间，是在游戏时间流动时进行的操作，增加该参数会真正增加划火柴时游戏内过去的时间。参数过小可能会导致部分手机无法识别拖动操作，仅在个人测试过的手机上可设置为1ms并保持稳定，0ms可能会导致无障碍错误并使应用闪退。\n',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color seedColor,
    required Color cardBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: seedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: seedColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required String number,
    required String title,
    required String description,
    required Color seedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: seedColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: seedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}