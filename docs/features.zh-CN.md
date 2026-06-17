# Diamond Transfer 中文功能介绍

**Diamond Transfer 是一个局域网优先的原生文件传输应用：两台设备之间可以像 LocalSend 一样直连，多人场景可以开启 Diamond Cloud，把一台设备变成同一 Wi-Fi 下的共享中枢。**

Diamond Transfer 的目标不是传统云盘，而是解决一个更具体的问题：在家庭、会议、教室、工作室、摄影现场等局域网环境里，让多个设备快速、直接、可控地交换文件。

## 核心定位

Diamond Transfer = 端对端直连传输 + 可选 Diamond Cloud 中枢共享会话。

它适合：

- 家庭设备之间传照片、视频、文档
- 会议现场多人收集和分发文件
- 教室里老师和学生互传资料
- 摄影现场把多台设备的素材集中到一台 Mac / NAS / 电脑
- 不想登录云服务、不想经过公网的本地传输

## 功能总览

| 功能 | 说明 |
| --- | --- |
| 同 Wi-Fi 发现 | 通过 Bonjour/mDNS 发现附近的 Diamond Transfer 设备。 |
| 端对端直连 | 保留类似 LocalSend 的一对一传输体验。 |
| Diamond Cloud 模式 | 一台设备作为局域网服务器，多个设备加入同一个共享会话。 |
| 双重身份 | Diamond Cloud 设备同时是普通直连设备和 Diamond Cloud 服务器。 |
| Diamond Cloud 存储配额 | 开启 Diamond Cloud 前显示剩余空间，并限制本次 session 可用容量。 |
| Diamond Cloud 保存目录 | 文件保存在 Diamond Cloud 设备的本地文件夹里，位置可见、可选择。 |
| 一次性文件 | 发送者选择哪些设备可见，所有目标设备打开后从 Diamond Cloud 自动删除。 |
| macOS 菜单栏 | 关闭主窗口后 Dock 图标隐藏，菜单栏入口继续保留。 |
| 原生体验 | 当前 demo 使用 SwiftUI 构建 macOS 原生界面。 |

## 端对端直连

每台设备打开 App 后，会在局域网里发布自己的 peer 节点。其他设备可以发现它，并把它作为直接传输目标。

这个模式适合简单的一对一发送：

- Mac 发文件到 iPhone
- Android 发照片到 Mac
- 两台电脑之间互传压缩包

## Diamond Cloud 中枢模式

任意一台设备可以开启 Diamond Cloud。开启后，这台设备会同时扮演两个角色：

- **Peer**：仍然可以被其他设备直接发现和传输
- **Diamond Cloud host**：作为共享会话的局域网服务器

其他设备打开 App 后，会看到两类对象：

- **Nearby Devices**：附近直连设备
- **Diamond Cloud**：可加入的共享中枢

## Diamond Cloud 存储空间

开启 Diamond Cloud 前，用户可以看到：

- 当前设备剩余存储空间
- Diamond Cloud 文件夹位置
- 本次 Diamond Cloud session 允许使用的存储配额

这避免 Diamond Cloud 无控制地占满本机磁盘。后续可以加入“记住此设备默认 Diamond Cloud 设置”。

## 一次性文件

发送者上传文件前可以选择“一次性文件”。

规则：

- 发送者选择当前 Diamond Cloud 中哪些设备可以看到
- 只有被选中的设备会在文件列表中看到它
- 文件行用红色小字标记“一次性文件”
- 每个目标设备打开后，Diamond Cloud 记录 viewed 状态
- 所有目标设备都打开后，Diamond Cloud 自动删除该文件
- 后加入 Diamond Cloud 的设备默认看不到旧的一次性文件

这是 Diamond Cloud 保留策略，不是 DRM。它不会承诺防截屏、防拍照或防复制。

## 当前原型状态

当前 macOS demo 已经实现真实的 LAN 发现和发布：

- 使用 `Network.framework` 和 Bonjour/mDNS
- 服务类型为 `_diamondtransfer._tcp`
- App 启动后始终发布 peer 节点
- 开启 Diamond Cloud 后额外发布 Diamond Cloud 节点
- 同一台 Mac 可以同时作为直连设备和 Diamond Cloud 主机

文件字节流传输仍处于 UI 模拟阶段。下一步是接上真实 TCP 控制通道和文件流。

## 技术关键词

LAN file sharing, Wi-Fi file transfer, LocalSend alternative, AirDrop alternative, peer-to-peer transfer, Diamond Cloud session, Bonjour, mDNS, Network.framework, one-time files, local cloud, 局域网文件传输, 局域网共享, 本地云。
