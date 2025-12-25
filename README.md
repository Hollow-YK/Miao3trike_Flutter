<div align="center">
  <img src="app/src/main/res/drawable/ic_cat_head.png" alt="Logo" width="100" height="100">

  <h1 align="center">Miao3trike</h1>

  <p align="center">
    Miao3trike：一个明日方舟手机版划火柴小工具的魔改版
    <br />
    <a href="https://github.com/SuperMaxine/Miao3trikeMod/issues">报告 Bug</a>
    ·
    <a href="https://github.com/SuperMaxine/Miao3trikeMod/pulls">发起请求</a>
  </p>

  <p align="center">
    <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android" alt="Platform" />
    <img src="https://img.shields.io/badge/Language-Kotlin%20%2F%20Java-purple?style=flat-square&logo=kotlin" alt="Language" />
    <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" />
    <img src="https://img.shields.io/github/stars/SuperMaxine/Miao3trikeMod?style=social" alt="Stars" />
  </p>
</div>

---

## 📖 简介 (Introduction)

**Miao3trikeMod** 是一个基于 [**Miao3trike**](https://github.com/ESHIWU/Miao3trike) 的 Android 应用。
因为明日方舟的返回键暂停键有CD而游戏内的触摸暂停键没有CD，本魔改使用更激进的无障碍模拟宏操作，替代人工划火柴、零帧撤退与放技能、逐帧步进。并且提供操作间延迟调整选项，极限可以于1ms内稳定划出火柴。
**可与原版同时存在！**

## 🚨 魔改版教程（Tutorial）

**Miao3trikeMod**相比原版操作复杂度高了很多，在魔改版中，功能使用方法如下：



- 划火柴：**第一次使用务必校准暂停按钮位置！（点击悬浮开关，将出现的蓝色按钮拖动到游戏中暂停按钮的真实位置，一次设置，永久生效）** 正常使用时，在**游戏暂停**状态下点击**悬浮开关**，开启划火柴操作录制，此时拖动干员并不会真的拖动干员，而是绘制一条拖放路径，松手后，应用会自动播放“点暂停→拖出干员→手机返回键”的宏操作，放置到位后之后需要自行调整干员朝向。
- 零帧撤退与放技能：在**游戏暂停**状态下按下手机的**音量+**按键，开启干员位置录制，此时点击干员位置，松手后，应用会自动播放“点暂停→点击干员→点暂停”的宏脚本，然后可以自己选择开干员技能或是撤退。
- 逐帧步进：在**游戏暂停**状态下按下手机的**音量-**按键，应用会自动播放“点暂停→等待→点暂停”的宏脚本，通过调整等待时间（“步进延迟”），可以以人类难以精确捕捉的时间逐帧步进游戏内时间，方便精细操作。

### 常见问题

1. 为什么一进去划火柴不成功反而还取消暂停了？
  - 有可能是模拟暂停按钮的位置不对，在划火柴模式下，将蓝色的示意点拖动到游戏中的暂停按钮位置再试试。
2. 为什么干员落地位置不是我放置的位置？
  - 因为干员拖动过程中地图会有倾斜效果，建议先选中干员将地图倾斜到位再录制拖放路径，从而避免自动操作时产生位置的干员落点偏移。
3. “启动延迟“是什么？
  - （TLDR：随便加，不影响划火柴，只影响你等脚本划完火柴的速度，但过低容易不稳定）录制拖放路径靠插入虚拟图层实现对手指位置的监控，如果参数中的启动延迟设置过小，会导致第一次暂停点击到虚拟图层从而取消暂停失败。最终表现为，划火柴失败，干员没放出来，并且解除了暂停。启动时间是在宏开始执行前的等待时间，即还没有解出暂停，因此增加这个参数并不会增加游戏内流动的时间。
4. “每步操作之间的延迟”是什么
  - 顾名思义，在划火柴“点暂停→拖出干员→手机返回键”每步操作之间的等待时间，同时也是零帧撤退与放技能“点暂停→点击干员→点暂停”每步操作之间的等待时间，一般0ms无问题，增加会增加操作时游戏内流过的时间。
5. “悬停延迟”是什么？
  - （TLDR：同“启动延迟“，也可以随便加，但过低容易不稳定）明日方舟将干员放在格子上需要你按着干员在格子上悬停一会儿才能确认位置并下落，如果直接拖过去0帧松手干员是落不下的。这个时间在脚本恢复暂停后才会开始等待，因此增加这个参数也不会增加游戏内流动的时间。
6. “拖动速度”是什么？
  - 是拖动干员到目标位置所需要的时间，是在游戏时间流动时进行的操作，增加该参数会真正增加划火柴时游戏内过去的时间。参数过小**可能会导致部分手机无法识别拖动操作**，仅在个人测试过的手机上可设置为1ms并保持稳定，0ms可能会导致无障碍错误并使应用闪退。

## 📸 界面预览 (Screenshots)

| 首页预览 |
|:---:|
| <img width="1439" height="3016" alt="20251220" src="https://github.com/user-attachments/assets/bc616806-0846-41ad-81bd-f10ebc267567" /> |

- 🎨 **精美 UI**：遵循 Material Design 设计规范。
- 🔧 **核心功能**：手机快速划火柴。
- 🌙 **深色模式**：完美支持 Android 系统深色主题。

## 🛠️ 技术栈 (Tech Stack)

* **语言**: Kotlin / Java
* **架构**: MVVM / MVP (根据实际情况修改)
* **UI**: XML / Jetpack Compose
* **网络**: Retrofit / OkHttp
* **图片加载**: Glide / Coil
* **依赖注入**: Hilt / Koin

## ⚡ 快速开始 (Getting Started)

如果你想在本地运行本项目，请按照以下步骤操作：

### 环境要求
* Android Studio Ladybug | 2024.2.1 或更高版本
* JDK 17+

### 安装步骤

1.  克隆仓库：
    ```bash
    git clone [https://github.com/SuperMaxine/Miao3trikeMod.git](https://github.com/SuperMaxine/Miao3trikeMod.git)
    ```
2.  在 Android Studio 中打开项目根目录。
3.  等待 Gradle 同步完成（Sync Project with Gradle Files）。
4.  连接 Android 设备或启动模拟器。
5.  点击 **Run** (Shift+F10) 运行应用。

## 🤝 贡献 (Contributing)

欢迎任何形式的贡献！如果你有好的想法：

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

## 📄 许可证 (License)

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件。

---

<div align="center">
  Created with ❤️ by <a href="https://github.com/ESHIWU">ESHIWU</a>
</div>
