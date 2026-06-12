# WebGuide

跨平台网页操作引导助手 - 让任何用户都能独立完成复杂的网页操作。

## 项目简介

WebGuide 是一个跨平台的移动端和桌面端应用，通过在目标网页上叠加实时引导层，帮助用户一步步完成复杂的网页操作，如注册 GitHub 账号、配置 Git 环境、注册 AWS 账号等。

### 核心特性

- **实时网页引导** - 在目标网页上叠加半透明遮罩和高亮提示，引导用户完成每一步操作
- **智能元素识别** - 自动识别网页上的表单字段、按钮等交互元素，多策略回退定位
- **跨平台支持** - 一套代码覆盖 iOS、Android、Windows、macOS
- **错误检测与恢复** - 自动检测操作错误并提供修复建议
- **离线任务包** - 下载引导任务到本地，无网络时也可查看步骤说明

### 技术栈

| 层级 | 技术 |
|------|------|
| 跨平台框架 | Flutter 3.x |
| 编程语言 | Dart |
| 网页渲染 | webview_flutter |
| 状态管理 | Riverpod |
| 本地存储 | Hive |
| 后端服务 | Supabase |

## 文档

| 文档 | 链接 |
|------|------|
| 产品需求文档 (PRD) | [docs/prd/web-guide-prd.html](docs/prd/web-guide-prd.html) |
| 技术设计文档 | [docs/design/web-guide-design.html](docs/design/web-guide-design.html) |

## 项目结构

```
webguide/
├── docs/
│   ├── prd/              # 产品需求文档
│   └── design/           # 技术设计文档
├── lib/
│   ├── core/             # 常量、主题、工具
│   ├── data/             # 数据模型、仓库、数据源
│   ├── domain/           # 业务实体、用例
│   ├── presentation/     # Providers、页面、组件
│   └── services/         # 引导引擎、WebView、同步
├── test/
└── pubspec.yaml
```

## 快速开始

```bash
# 克隆项目
git clone https://github.com/weijia/webguide.git
cd webguide

# 获取依赖
flutter pub get

# 运行（调试模式）
flutter run
```

## 构建发布

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 发起 Pull Request

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
