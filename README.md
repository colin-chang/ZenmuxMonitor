# ZenMux Monitor

macOS 菜单栏应用，实时查看 [ZenMux](https://zenmux.ai) 订阅配额与用量。

## 功能

- 菜单栏常驻，显示当前 5 小时配额使用百分比
- 左键点击图标展开用量面板：5 小时 / 7 天配额进度条、PAYG 余额、Flow 汇率
- 右键点击图标弹出菜单：刷新、设置、退出
- 用量颜色预警（绿 / 橙 / 红）
- API Key 存储于 macOS Keychain
- 可配置自动刷新间隔（1 / 5 / 15 / 30 分钟）

## 系统要求

- macOS 14.0 (Sonoma) 及以上
- Xcode 16.0 及以上

## 构建与运行

项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理工程文件：

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 生成 .xcodeproj
xcodegen generate

# 构建运行
open ZenmuxMonitor.xcodeproj
```

或直接用命令行：

```bash
xcodebuild -scheme ZenmuxMonitor -configuration Debug build
```

## 配置 API Key

1. 在 [ZenMux 管理面板](https://zenmux.ai/platform/management) 获取 Management API Key
2. 左键点击菜单栏图标 → 点击齿轮图标 → 粘贴 API Key → 保存

## 技术栈

- Swift 6.0 / SwiftUI / AppKit
- `@Observable` 宏 + `NSStatusItem` + `NSPopover`
- Security.framework（Keychain）
- 零第三方依赖

## 许可证

[MIT](LICENSE)
