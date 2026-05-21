# ZenMux Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)
[![Release](https://img.shields.io/github/v/release/colinchang/ZenmuxMonitor?include_prereleases)](../../releases)

[English Version](./README.md) | 中文版本

## [ZenMux](https://zenmux.ai/invite/1C3QLF) 是什么？

[ZenMux](https://zenmux.ai/invite/1C3QLF) 是一个统一的大模型聚合器 —— 一个 API Key 即可调用 ChatGPT / Claude / Gemini / DeepSeek / GLM 等国内外主流模型。中国大陆直连可用，无需科学上网，无需海外信用卡，支持支付宝付费。提供智能路由、自动故障转移和保险赔付机制，安全稳定，性价比高。

## ZenMuxMonitor 是什么？

轻量级 macOS 菜单栏应用，实时查看 [ZenMux](https://zenmux.ai/invite/1C3QLF) 订阅配额与用量。

![示例图片](./sample.webp)

## 功能

- 菜单栏常驻，显示当前 5 小时配额使用百分比
- 左键点击图标展开用量面板：5 小时 / 7 天配额进度条、PAYG 余额、Flow 汇率
- 右键点击图标弹出菜单：刷新、设置、退出
- 用量颜色预警（绿 / 橙 / 红）
- API Key 存储于 macOS Keychain
- 可配置自动刷新间隔（1 / 5 / 15 / 30 分钟）
- 支持英文与简体中文，自动跟随系统语言

## 安装

从 [Releases](../../releases) 页面下载最新 DMG，将 **ZenMux Monitor** 拖入应用程序文件夹即可。

> 由于应用未经 Apple 开发者证书签名，macOS 可能会提示「"ZenMux Monitor"已损坏，无法打开」。请在终端执行以下命令解除隔离属性：
>
> ```bash
> sudo xattr -rd com.apple.quarantine "/Applications/ZenmuxMonitor.app"
> ```
>
> 执行后即可正常打开应用。

## 配置 API Key

1. 在 [ZenMux 管理面板](https://zenmux.ai/platform/management) 获取 Management API Key
2. 左键点击菜单栏图标 → 点击齿轮图标 → 粘贴 API Key → 保存

## 系统要求

- macOS 14.0 (Sonoma) 及以上
- Xcode 16.0 及以上（开发所需）

## 开发

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

## 技术栈

- Swift 6.0 / SwiftUI / AppKit
- `@Observable` 宏 + `NSStatusItem` + `NSPopover`
- Security.framework（Keychain）
- 零第三方依赖

## 贡献

欢迎贡献！请阅读[贡献指南](./CONTRIBUTING.md)了解详情。

## 更新日志

详见 [CHANGELOG.md](./CHANGELOG.md)。

## 安全

如发现安全漏洞，请私下报告。详见 [SECURITY.md](./SECURITY.md)。

## 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。
