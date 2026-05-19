# ZenmuxMonitor 开发计划

## 背景

订阅 Zenmux 模型服务后，需要频繁打开网页查看配额余量（5h/7d/月度使用量、PAYG 余额、Flow 汇率等），操作繁琐。目标是构建一个 macOS 原生应用，分两阶段实现：

1. **菜单栏应用** — 常驻菜单栏，点击图标弹出面板显示核心数据
2. **桌面小组件** — WidgetKit 小组件，可放置在桌面或通知中心

ZenMux 提供了正式的 Management API（Bearer Token 认证），无需爬虫或模拟登录。

---

## API 端点清单

| 端点 | 路径 | 用途 | 阶段 |
|------|------|------|------|
| Subscription Detail | `GET /api/v1/management/subscription/detail` | 套餐/配额余量（核心） | Phase 1 |
| PAYG Balance | `GET /api/v1/management/payg/balance` | PAYG 余额/赠送额度 | Phase 1 |
| Flow Rate | `GET /api/v1/management/flow_rate` | Flow 汇率 | Phase 2 |
| Statistics Timeseries | `GET /api/v1/management/statistics/timeseries` | 使用趋势 | Phase 3 |
| Statistics Leaderboard | `GET /api/v1/management/statistics/leaderboard` | 模型排行 | Phase 3 |
| Statistics Market Share | `GET /api/v1/management/statistics/market_share` | 供应商占比 | Phase 3 |

所有端点认证方式：`Authorization: Bearer $ZENMUX_MANAGEMENT_KEY`

---

## 前置要求

- **Xcode**（WidgetKit 扩展必须）：Phase 1 菜单栏应用可用 SPM + 命令行构建，Phase 2 小组件需要 Xcode
- **Apple Developer Account**：如需签名分发则必要，本地调试不需要
- **ZENMUX_MANAGEMENT_KEY**：用户需在 https://zenmux.ai/platform/management 创建

---

## Phase 1：项目骨架 + 核心数据层

**目标**：搭建 Xcode 项目结构，实现 API 网络层和数据模型，确保能成功调用 API 并解析数据。

### 1.1 创建 Xcode 项目

```
ZenmuxMonitor/
├── ZenmuxMonitor.xcodeproj
├── ZenmuxMonitor/                    # 主 App target
│   ├── App/
│   │   └── ZenmuxMonitorApp.swift    # App 入口
│   ├── Models/
│   │   ├── SubscriptionDetail.swift   # 订阅/配额数据模型
│   │   ├── PAYGBalance.swift          # PAYG 余额数据模型
│   │   ├── FlowRate.swift             # Flow 汇率数据模型
│   │   └── QuotaWindow.swift          # 5h/7d/月度配额窗口模型
│   ├── Services/
│   │   ├── ZenmuxAPIClient.swift      # API 客户端（网络请求）
│   │   └── KeychainManager.swift      # Keychain 安全存取 API Key
│   ├── ViewModels/
│   │   └── UsageViewModel.swift       # 数据聚合 + 刷新逻辑
│   └── Views/
│       └── (Phase 2 填充)
├── ZenmuxMonitorWidget/              # Widget Extension target（Phase 4）
│   └── (Phase 4 填充)
└── Shared/                           # App 与 Widget 共享代码
    ├── Models/                       # Codable 数据模型（符号链接或共享 target）
    └── Services/                     # API 客户端
```

### 1.2 数据模型（Codable）

根据 API 响应结构定义：

**SubscriptionDetail** — 包含：
- `plan`: 套餐名称（Ultra/Pro/...）
- `status`: 账户状态（healthy/...）
- `quotaWindows`: 数组，每项含 `window`(5h/7d/monthly)、`usagePercentage`、`flowsUsed`/`flowsMax`、`usdUsed`/`usdMax`、`resetsAt`

**PAYGBalance** — 包含：
- `totalCredits`、`topUpCredits`、`bonusCredits`

**FlowRate** — 包含：
- `baseRate`、`effectiveRate`

> 注意：实际字段名需在首次 API 调用后根据真实响应调整。先基于 SKILL.md 文档中的描述建模。

### 1.3 API 客户端

`ZenmuxAPIClient`（async/await）：
- 基础 URL：`https://zenmux.ai`
- 认证：从 Keychain 读取 Management Key，注入 `Authorization: Bearer` header
- 方法：`fetchSubscriptionDetail()`、`fetchPAYGBalance()`、`fetchFlowRate()`
- 错误处理：401/403（Key 无效）、422（限流）、网络错误
- 超时：10 秒

### 1.4 Keychain 安全存储

`KeychainManager`：
- 使用 Security.framework 存储 Management API Key
- 不使用 UserDefaults（API Key 是敏感信息）
- 提供 save/get/delete 接口

### 1.5 验收标准

- [ ] Xcode 项目可编译运行
- [ ] API Key 可存入/读取 Keychain
- [ ] 三个核心 API 可成功调用并解码为 Swift 模型
- [ ] 网络错误有基本的错误类型处理

---

## Phase 2：菜单栏应用 MVP

**目标**：实现常驻菜单栏的应用，点击图标弹出面板显示配额数据。

### 2.1 App 入口

```swift
@main
struct ZenmuxMonitorApp: App {
    // NSMenuExtra 模式，无 Dock 图标
    init() {
        NSApp.setActivationPolicy(.accessory)
    }
}
```

使用 `MenuBarExtra`（macOS 13+）实现菜单栏图标：
- 图标：SF Symbols `gauge.with.dots.needle.bottom.50percent`（或自定义）
- 点击弹出窗口（`.window` style），不是下拉菜单

### 2.2 主面板 UI

弹出面板内容，从上到下：

1. **订阅信息区**
   - 套餐名称 + 到期日
   - 账户状态指示灯（绿色 = healthy）

2. **配额使用区**（核心区域）
   - 三行进度条：5-hour / 7-day / Monthly
   - 每行：标签 + 百分比 + 已用/最大（Flows & USD）+ 重置时间
   - 使用量 > 80% 时进度条变橙/红色警告

3. **PAYG 余额区**（如有）
   - 总额度 / 充值额度 / 赠送额度

4. **Flow 汇率区**
   - 基础汇率 / 实际汇率

5. **底部操作栏**
   - 刷新按钮 + 上次刷新时间
   - 设置齿轮图标

### 2.3 UsageViewModel

`ObservableObject` / `@Observable`：
- 发布属性：`subscriptionDetail`、`paygBalance`、`flowRate`、`isLoading`、`lastUpdated`、`errorMessage`
- `refresh()`：并发调用 subscription + payg + flow_rate
- `startAutoRefresh(interval: TimeInterval)`：Timer 定时刷新（默认 5 分钟）
- 错误状态：API Key 未配置 / Key 无效 / 网络失败

### 2.4 验收标准

- [ ] 菜单栏图标常驻显示
- [ ] 点击弹出面板，显示真实 API 数据
- [ ] 配额进度条正确渲染，>80% 有颜色警告
- [ ] 手动刷新 + 自动定时刷新工作正常
- [ ] 无 Dock 图标，不抢焦点

---

## Phase 3：设置界面 + 体验打磨

**目标**：完善设置流程、错误处理、视觉细节，达到日常可用水平。

### 3.1 设置窗口（独立 Window）

- **API Key 管理**：输入/更新/删除 Management Key
- **刷新间隔**：下拉选择（1/5/15/30 分钟）
- **开机自启**：Launch at Login（使用 `SMAppService`，macOS 13+）
- **通知阈值**：配额使用超过 X% 时发送系统通知

### 3.2 首次启动引导

检测 Keychain 中无 API Key → 弹出设置窗口引导用户输入：
- 简短说明文字 + 输入框
- "获取 API Key" 链接跳转 https://zenmux.ai/platform/management
- 输入后验证（调一次 subscription/detail），成功则保存

### 3.3 菜单栏图标状态

根据配额使用量动态改变图标：
- 正常（<50%）：默认图标
- 警告（50%-80%）：黄色图标
- 危险（>80%）：红色图标

使用 `MenuBarExtra` 的 `label` 动态更新 + SF Symbols 变体。

### 3.4 系统通知

- 配额超过阈值时推送 `UNUserNotificationCenter` 通知
- 点击通知打开面板
- 可在设置中关闭

### 3.5 错误处理打磨

- API Key 未配置 → 面板显示引导提示
- Key 无效（401/403）→ 提示重新输入
- 网络失败 → 显示上次成功数据 + "离线" 标记 + 重试按钮
- 限流（422）→ 自动退避重试

### 3.6 验收标准

- [ ] 首次启动引导流程完整
- [ ] 设置窗口可管理 API Key、刷新间隔、开机自启
- [ ] 菜单栏图标反映配额状态
- [ ] 超阈值通知正常推送
- [ ] 网络异常时优雅降级

---

## Phase 4：WidgetKit 桌面小组件

**目标**：添加 macOS 桌面小组件，可放置在桌面或通知中心，实时显示配额概览。

### 4.1 项目配置

- 在 Xcode 项目中添加 Widget Extension target `ZenmuxMonitorWidget`
- 配置 App Group（如 `group.com.zenmux.monitor`）用于共享数据
- 将 Models 和 API 客户端代码加入 Widget target 的 Compile Sources（或使用 Swift Package 共享）

### 4.2 数据共享策略

Widget Extension 和主 App 运行在独立进程中，需要通过 App Group 共享数据：

- **主 App 侧**：每次刷新 API 后，将最新数据序列化为 JSON 写入 App Group 的共享 UserDefaults 或共享文件
- **Widget 侧**：`TimelineProvider` 读取共享数据，不直接调用 API（Widget 有内存和时间限制）
- 共享数据结构：`SharedUsageData` — 包含所有展示数据 + `lastUpdated` 时间戳

```
App 调 API → 解码 → 写入 App Group Container → Widget TimelineProvider 读取
```

### 4.3 Widget 尺寸

支持三种尺寸：

| 尺寸 | 内容 | 适用场景 |
|------|------|---------|
| **Small** | 配额总览（7d 百分比 + 进度环） | 桌面角落/Smart Stack |
| **Medium** | 5h + 7d + 月度三行进度条 + 套餐名 | 桌面/通知中心 |
| **Large** | Medium + PAYG 余额 + Flow 汇率 + 趋势迷你图 | 通知中心详情 |

### 4.4 Timeline 策略

- `TimelineEntry`：包含 `SharedUsageData` + `date`
- 刷新策略：
  - `atEnd`：每次 Timeline 结束时请求刷新
  - 每 5 分钟一个 entry，最多 12 个（覆盖 1 小时）
  - 实际刷新由系统调度，可能延迟
- 主 App 刷新数据时通过 `WidgetCenter.shared.reloadAllTimelines()` 主动触发 Widget 刷新

### 4.5 Widget UI

使用 SwiftUI Canvas / View：
- Small：环形进度图（7d 使用百分比为中心数字）
- Medium：三行水平进度条 + 配色方案（绿→黄→红渐变）
- Large：Medium 基础上追加详细数据卡片

### 4.6 Widget 交互

- 点击 Widget → 打开主 App 对应面板（deep link via `widgetURL` 或 `Link`）
- 可选：Button intent 刷新（iOS 17+ / macOS 14+ 的 `AppIntent` 交互）

### 4.7 验收标准

- [ ] Widget Extension 可编译并在桌面/通知中心显示
- [ ] 三种尺寸 UI 正确渲染
- [ ] 主 App 刷新数据后 Widget 同步更新
- [ ] 点击 Widget 可打开主 App
- [ ] 离线时显示最后有效数据 + "离线" 标记

---

## Phase 5：扩展功能 + 打磨

**目标**：加入趋势图表、模型排行等高级功能，完善分发。

### 5.1 使用趋势图（App 面板）

- 在主面板底部增加"趋势"标签页
- 调用 `statistics/timeseries` 获取近 7 天/28 天的 token/cost 趋势
- 使用 Swift Charts 渲染折线图

### 5.2 模型排行

- 调用 `statistics/leaderboard` 获取 Top 5 模型
- 在面板中以排名列表展示

### 5.3 Widget 趋势迷你图

- Large Widget 底部显示最近 7 天趋势迷你折线图

### 5.4 分发

- 代码签名 + Notarization
- 两种分发方式：
  - **DMG 安装包**：直接下载安装
  - **Mac App Store**（可选，需审核周期）

### 5.5 验收标准

- [ ] 趋势图正确渲染
- [ ] 模型排行数据展示
- [ ] 应用可签名分发

---

## 技术选型总结

| 项目 | 选择 | 理由 |
|------|------|------|
| 语言 | Swift 6 | 原生性能，与系统 API 零摩擦 |
| UI 框架 | SwiftUI | 声明式、WidgetKit 原生支持 |
| 最低版本 | macOS 13+ | MenuBarExtra + SMAppService |
| 网络层 | URLSession + async/await | 无第三方依赖 |
| 安全存储 | Keychain Services | API Key 不落盘明文 |
| 数据共享 | App Group + UserDefaults | App 与 Widget 进程间通信 |
| 图表 | Swift Charts | 系统原生，Phase 5 使用 |
| 包管理 | SPM | 仅用于可能的内部模块化 |
| 第三方依赖 | 无 | 保持轻量，减少维护负担 |

---

## 开发时间估算

| 阶段 | 内容 | 预估时间 |
|------|------|---------|
| Phase 1 | 项目骨架 + 数据层 | 2-3 小时 |
| Phase 2 | 菜单栏 MVP | 3-4 小时 |
| Phase 3 | 设置 + 打磨 | 2-3 小时 |
| Phase 4 | WidgetKit 小组件 | 3-4 小时 |
| Phase 5 | 扩展 + 分发 | 2-3 小时 |
| **总计** | | **12-17 小时** |
