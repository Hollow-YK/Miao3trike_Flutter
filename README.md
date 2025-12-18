Miao3trike / VolumeKeyMapper 设计与复现文档
==========================================

项目概览
--------
- 目标：通过无障碍拦截音量 + 键，模拟两次全局返回，实现“划火柴/暂停闪回”效果。
- 形态：纯本地 Android 应用，无后端依赖；核心是前台悬浮窗服务 + 无障碍服务 + 主界面引导。
- 包与命名：`package="com.ark3trike.matches"`，源码路径位于 `app/src/main/java/com/example/volumekeymapper`（需后续统一）。
- 运行范围：minSdk 21，target/compile 34；已生成 APK：`app/release/app-release.apk`。

技术栈与构建
------------
- 语言：Java 8（`sourceCompatibility`/`targetCompatibility` 1.8）。
- 依赖：AndroidX AppCompat 1.6.1、Material 1.9.0、ConstraintLayout 2.1.4；测试依赖 JUnit4/Espresso（未使用）。
- UI：传统 View（ConstraintLayout + drawable/ripple）；Compose 模板文件存在但未使用。
- 构建：Gradle（根 `build.gradle.kts`，模块 `app/build.gradle`）；根 settings 配置 `RepositoriesMode.FAIL_ON_PROJECT_REPOS`。

权限与系统集成
--------------
- 声明权限：`SYSTEM_ALERT_WINDOW`、`FOREGROUND_SERVICE`、`POST_NOTIFICATIONS`、`FOREGROUND_SERVICE_SPECIAL_USE`、`WRITE_SETTINGS`（小米特殊）。
- 前台服务：`FloatingWindowService` 使用 `specialUse` 前台类型，渠道 ID `miao3trike_foreground`。
- 无障碍：`VolumeKeyAccessibilityService` 配置于 `res/xml/accessibility_service_config.xml`，启用 `flagRequestFilterKeyEvents` 以拦截实体键。
- 悬浮窗：使用 `TYPE_APPLICATION_OVERLAY`（≥O）或 `TYPE_PHONE`（<O）添加视图。

功能说明（用户流）
----------------
1) 主界面引导用户分别授予无障碍权限与悬浮窗权限（跳转系统设置页）。  
2) 用户开启“开关” → 启动前台悬浮窗服务。  
3) 屏幕出现可拖拽浮窗，短按浮窗切换功能开关。  
4) 当功能开启时，无障碍服务拦截音量 + 按键，连续执行两次全局返回（间隔 300ms）。  
5) 用户可在主界面关闭服务；界面恢复时同步服务/权限状态。

核心架构与模块
--------------
- `MainActivity.java` (`app/src/main/java/com/example/volumekeymapper/MainActivity.java`)
  - 跳转系统设置：无障碍 (`Settings.ACTION_ACCESSIBILITY_SETTINGS`)，悬浮窗 (`ACTION_MANAGE_OVERLAY_PERMISSION` ≥M)。
  - 校验权限并启动/停止 `FloatingWindowService`；更新指示灯与 Switch。
  - 状态检测：`Settings.canDrawOverlays`、`AccessibilityManager.getEnabledAccessibilityServiceList`、`ActivityManager.getRunningServices`。
- `FloatingWindowService.java` (`app/src/main/java/com/example/volumekeymapper/FloatingWindowService.java`)
  - 前台服务；创建通知渠道/通知后运行。
  - 加载 `res/layout/floating_button.xml` 浮窗；`Gravity.TOP|START` 以左上角坐标支持自由拖拽。
  - 短按浮窗 → 翻转 `VolumeKeyAccessibilityService.functionEnabled`，切换图标 `ic_float_on/off`。
  - 静态状态：`isRunning`、`instance`；提供 `stopService(Context)`。
- `VolumeKeyAccessibilityService.java` (`app/src/main/java/com/example/volumekeymapper/VolumeKeyAccessibilityService.java`)
  - 当 `functionEnabled` 为真且收到 `KEYCODE_VOLUME_UP` ACTION_DOWN → 执行两次 `performGlobalAction(GLOBAL_ACTION_BACK)`（300ms 间隔），消费事件。
  - 状态不持久化，进程重启默认关闭。
- `DebugHelper.java`：系统/权限/内存/服务生命周期日志工具，当前未接入业务。

关键资源与配置
--------------
- Manifest：`app/src/main/AndroidManifest.xml`（权限、Activity、前台服务、无障碍服务 + metadata）。
- 无障碍配置：`app/src/main/res/xml/accessibility_service_config.xml`（请求过滤键事件、反馈类型、超时等）。
- 主界面布局：`app/src/main/res/layout/activity_main.xml`（权限按钮、状态指示、服务开关、说明卡片、作者链接）。
- 浮窗布局：`app/src/main/res/layout/floating_button.xml`（60dp 按钮 + ripple）。
- 主题与颜色：`app/src/main/res/values/themes.xml`（默认 Material DarkActionBar），`app/src/main/res/values/colors.xml`（深色背景 + 绿/橙主辅色）；文案 `app/src/main/res/values/strings.xml`。

状态与数据流
------------
- 运行时状态：`VolumeKeyAccessibilityService.functionEnabled`（功能开关，静态）、`FloatingWindowService.isRunning`/`instance`（服务存活）。
- 同步策略：`MainActivity.onResume` 检查服务/权限并更新 UI；浮窗点击直接改写静态开关。
- 无持久化：服务或进程被杀后，功能开关恢复为默认关闭。

运行时时序（概要）
-----------------
1) App 启动 → `MainActivity.onCreate` 初始化 UI，隐藏 ActionBar，设置状态栏颜色。  
2) 用户点击权限按钮跳转系统页 → 授权无障碍/悬浮窗。  
3) 用户打开开关 → `checkPermissionsAndStart()` 校验权限 → `startForegroundService(FloatingWindowService)`。  
4) `FloatingWindowService.onCreate` → 创建通知渠道 → `startForeground` → 校验悬浮权限 → 创建浮窗 → 设置拖拽与点击。  
5) 用户点击浮窗 → `toggleFunction()` 翻转 `functionEnabled`，更新浮窗图标。  
6) 无障碍收到音量 + （按下且开关为真）→ 连续两次全局返回。  
7) 用户关闭开关或服务销毁 → 移除浮窗，`isRunning` 置 false；`MainActivity.onResume` 再同步 UI。

限制与风险
----------
- 包名/源码路径不一致，可能影响无障碍配置匹配和可维护性，重构需统一。
- 功能开关未持久化，服务/进程重启需重新开启。
- 仅支持音量 + 映射，无其他按键/动作配置，也无目标应用过滤。
- 无权限状态监听回调（仅刷新时检查），缺少错误提示持久化。
- Compose 主题模板未用，主题/色彩存在割裂。
- Android 14+ `specialUse` 前台服务需合规场景，上架需审查。

复现与重构建议
--------------
1) 包与命名统一：调整 `namespace`、`applicationId` 与源码路径一致。  
2) 状态持久化：用 DataStore/SharedPreferences 保存功能开关；服务重启恢复。  
3) 事件与状态解耦：用 Binder/Broadcast/ViewModel 替代静态字段，统一状态源。  
4) 权限监听：接入 `AccessibilityManager.AccessibilityStateChangeListener`，并在返回授权页后刷新悬浮窗权限状态。  
5) 功能扩展：抽象按键→动作映射表，支持音量 -、自定义动作、延迟配置、按应用过滤。  
6) UI/主题整理：删除未用 Compose 模板或改为 Compose；统一颜色与主题风格。  
7) 监控与错误：加日志落盘/提示，前台通知可提供快捷入口。  
8) 兼容性：验证 Android 6/8/10/14 的悬浮窗、前台服务、无障碍行为差异。  
9) 发布准备：检查 `FOREGROUND_SERVICE_SPECIAL_USE` 合规性，必要时降级为标准类型并调整通知。  

测试建议
--------
- 单元：权限检查逻辑（覆盖 M+ 悬浮窗）、无障碍配置解析、状态持久化读写。  
- Robolectric/Instrumentation：浮窗点击/拖拽行为，前台通知创建，Activity 与服务交互（开关状态同步）。  
- 手动：不同厂商系统的无障碍开启/悬浮窗授权流程；音量键冲突场景；进程被杀后的恢复。  

目录索引（关键文件）
------------------
- 代码：`app/src/main/java/com/example/volumekeymapper/MainActivity.java`, `FloatingWindowService.java`, `VolumeKeyAccessibilityService.java`, `DebugHelper.java`。  
- 配置：`app/src/main/AndroidManifest.xml`, `app/src/main/res/xml/accessibility_service_config.xml`。  
- 资源：`app/src/main/res/layout/activity_main.xml`, `app/src/main/res/layout/floating_button.xml`, `app/src/main/res/values/strings.xml`, `app/src/main/res/values/colors.xml`。  
- 输出：`app/release/app-release.apk`。  
