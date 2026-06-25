# Alto Cloud（高积云）产品建设清单

本清单记录高积云从当前 macOS 原型走向跨设备局域网协作工具的建设方向。优先级会随真实测试、设备覆盖和你的后续产品决策调整。

## 当前原型

- macOS SwiftUI 原生应用壳。
- Bonjour/mDNS 发现 `_altocloud._tcp`。
- Quick Send 节点常驻发布。
- Shared Cloud 会话发布。
- Shared Cloud 存储配额、保存目录和文件队列 UI。
- One-Time Drop 可见性与打开后删除规则模拟。
- Script Relay 脚本中继 UI 原型：任务创建、目标选择、权限申请、审批、运行状态和日志回传模拟。

## 近期建设

- 建立真实 TCP 控制通道。
- 实现 `joinSharedCloud -> uploadIntent -> uploadAccepted -> file stream`。
- 文件字节流传输、进度、失败重试和取消。
- Shared Cloud 文件元数据持久化。
- Script Relay 协议落地：`scriptRunIntent`、审批结果、运行状态和日志回传。
- Script Relay 安全边界：任务级权限、运行超时、日志审计、脚本来源标识。

## 中期建设

- iOS/iPadOS 客户端。
- iPadOS 内置 Python runtime 可行性验证。
- M 系列 iPad 作为 Python 执行节点的沙盒运行目录。
- 任务签名或来源校验。
- 脚本结果文件回传到发送设备或 Shared Cloud。
- 局域网多设备兼容性测试。
- 可选端到端加密。

## 远期建设

- Android 客户端。
- Windows 客户端。
- 跨平台协议一致性测试套件。
- 设备能力画像：存储、CPU、Python runtime、网络状态、电量。
- 局域网设备池调度：选择空闲设备运行任务。
- 云端中继可选模式：不同网络下的任务和文件转发。

## 暂不承诺

- 不承诺绕过 iOS/iPadOS 沙盒限制。
- 不承诺后台无限常驻执行任意脚本。
- 不承诺脚本拥有系统级权限。
- One-Time Drop 是保留规则，不是 DRM。
