# Alto Cloud（高积云）功能介绍

**Alto Cloud 是一个局域网优先的原生文件共享应用：两台附近设备之间使用 Quick Send，多人场景则开启 Shared Cloud。**

它面向家庭、会议、教室、工作室和拍摄现场等场景，让多个设备无需账号、无需公网云盘，也能快速交换文件。

## 产品结构

Alto Cloud = **Quick Send + 可选的 Shared Cloud 会话**。

- **Quick Send（快速发送）**：附近设备之间的一对一发送。
- **Shared Cloud（共享云）**：由一台设备托管的临时局域网共享空间。
- **One-Time Drop（一次性投递）**：所有指定接收设备打开后自动删除。

## 核心功能

| 功能 | 行为 |
| --- | --- |
| 同 Wi-Fi 发现 | 通过 Bonjour/mDNS 发现附近的 Alto Cloud 设备。 |
| Quick Send | 每台设备都可作为一对一快速发送目标。 |
| Shared Cloud | 一台设备作为局域网服务器，多个设备加入同一共享会话。 |
| 双重身份 | Shared Cloud 主机仍然可以作为 Quick Send 目标。 |
| 存储配额 | 限制 Shared Cloud 会话可使用的本地磁盘空间。 |
| 可见本地目录 | 由主机选择共享文件的实际保存位置。 |
| One-Time Drop | 仅指定设备可见，并在所有目标设备打开后删除。 |

## Shared Cloud 存储

开启 Shared Cloud 前，主机可以查看可用容量、选择保存目录，并设置本次会话的存储上限。文件保存在主机设备上，不会上传到公网云服务。

## One-Time Drop 规则

发送者选择目标设备；之后加入 Shared Cloud 的设备默认无法看到旧的一次性投递。只有所有指定目标都打开文件后，Alto Cloud 才会自动删除它。

这是一条文件保留规则，不是 DRM，也不承诺防截屏、防拍照或防止打开后的复制。

## 局域网基础

- Bonjour 服务类型：`_altocloud._tcp`
- 始终发布 Quick Send 节点
- Shared Cloud 开启时额外发布共享节点
- 同一台 Mac 可以同时作为 Quick Send 目标和 Shared Cloud 主机

当前原型已实现局域网发现与模拟文件状态；真实控制通道和文件流传输是下一阶段。
