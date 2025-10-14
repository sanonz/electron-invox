# Invox Setup（安装/卸载器）

本项目基于 [Invox Setup](https://github.com/sanonz/invox-setup) 美化安装界面应用开发，提供了功能完整的 Windows 应用安装/卸载解决方案。具有以下特点：

- **Electron**：提供 Electron 一键打包支持
- **轻量级**：整体体积仅 2MB+，无需额外依赖
- **数据上报**：内置 Analytics 支持，可追踪安装/卸载行为
- **界面灵活**：采用类 HTML 的 XML 布局方式，易于定制
- **国际化**：支持中英文等多语言切换
- **用户友好**：提供进度显示、协议确认、路径选择等完整安装体验

## 界面预览

| 快速安装 | 自定义安装 | 卸载界面 |
|:---:|:---:|:---:|
| ![快速安装](https://github.com/sanonz/invox-setup/raw/setup/preview/quick.png) | ![自定义安装](https://github.com/sanonz/invox-setup/raw/setup/preview/custom.png) | ![卸载界面](https://github.com/sanonz/invox-setup/raw/setup/preview/uninstall.png) |

## 使用说明

### 安装说明

#### 安装 Visual Studio 2022 环境

1. 下载安装工具：[Visual Studio Community](https://visualstudio.microsoft.com/zh-hans/thank-you-downloading-visual-studio/?sku=Community)
2. 选择勾选：`使用 C++ 的桌面开发`、`C++ ATL for latest v143 build tools (x86 & x64)`
3. 执行下载安装

#### 下载源码

```bash
$ git clone --recurse-submodules git@github.com:sanonz/electron-invox.git
```

#### 安装依赖

```bash
$ npm install
```

### 构建应用

一行命令即可构建 Electron 和 Invox Setup

```bash
# For windows
$ npm run build:invox
```

运行 `dist/InvoxSetup-1.0.0.exe` 查看效果

### 加入已有项目

添加 Invox Setup 作为子仓库

```bash
$ git submodule add git@github.com:sanonz/invox-setup.git invox
```

下载 [build-invox.bat](https://raw.githubusercontent.com/sanonz/electron-invox/refs/heads/main/build-invox.bat) 构建脚本，添加构建命令

```json
{
  // ...
  "scripts": {
    "build": "electron-vite build",
    "build:unpack": "npm run build && electron-builder --dir",
    "build:invox": "npm run build:unpack && build-invox.bat"
  },
  // ...
}
```

运行命令即可构建

```bash
$ npm run build:invox
```
