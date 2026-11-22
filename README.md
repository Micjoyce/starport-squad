# 星港小队 · Starport Squad

在环形行星下夺回星港：步枪突击、屋顶狙击、指挥小队，或在创造模式部署士兵、机甲与炮台。

使用 Godot 4.5 / GDScript 制作的科幻工业风 3D 射击游戏，支持第一 / 第三人称。当前为 **0.16.1 开发预览**，Windows 与 macOS 共用一套工程。

[下载 Windows x64](https://github.com/Micjoyce/starport-squad/releases/tag/v0.16.1) · [下载 macOS 预览](https://github.com/Micjoyce/starport-squad/releases/tag/v0.16.0) · [反馈问题](https://github.com/Micjoyce/starport-squad/issues)

## 实机演示

https://github.com/user-attachments/assets/acdaef10-f910-4493-a4ac-1157dd91e5d5

36 秒原生引擎录制，保留游戏配乐与音效。镜头和操作由脚本驱动，展示当前开发预览画面。

[视频附件与讨论](https://github.com/Micjoyce/starport-squad/issues/1) · [录制方法](docs/PROMO.md)

## 目前可以玩什么

- **星港战役**：与小队会合、防守登陆区、突破外环、夺取核心。
- **自由战斗**：选择难度，使用步枪、霰弹枪、重型狙击枪等装备；切换第一 / 第三人称。
- **创造模式**：在 100×100 米场地部署双方兵种、AI 机甲与炮台，开战、训练、锻造和保存场景。

项目持续开发中；当前没有真实联网匹配，机甲为 AI 单位。已实现内容与待办详见 [开发状态](docs/STATUS.md)。

## 快速运行

1. 安装官方 **Godot 4.5 Standard**（无需 .NET）。
2. 在 Godot 项目管理器导入 `outputs/StarportSquad/project.godot`。
3. 等待素材导入，按 F6 运行当前场景或 F5 运行主场景。
4. 启动平板界面选择简单、困难、噩梦、超级噩梦、超级困难，或随机难度，然后进入主菜单。

Windows 开发与交接见 [docs/WINDOWS.md](docs/WINDOWS.md)，当前状态见 [docs/STATUS.md](docs/STATUS.md)。Windows 和 macOS 共用当前工程。[下载 Windows x64 游戏](https://github.com/Micjoyce/starport-squad/releases/tag/v0.16.1)。Windows 一键打包与自动构建见上述 Windows 文档；历史 macOS 包及源工程快照保留在仓库 Releases 中。

## 目录

- `outputs/StarportSquad/`：唯一当前可编辑工程，含场景、脚本、音频、字体、图像和音频生成工具。
- `outputs/*.png`：历次实机截图，部分反映旧版本。
- `outputs/*.md` 和工程中的说明：原始版本说明与测试记录，按其中版本阅读。
- `tests/`：可重跑的启动难度检查。
- `tools/`：跨平台 Windows 打包脚本和 CI 官方工具安装器。
- `.github/workflows/windows.yml`：Windows 原生构建与导出包功能检查。
- `archive/development/`：历史开发脚本、补丁生成器和测试日志，仅用于追溯；不要当作当前工程入口运行。
- `docs/`：开发状态、Windows 接续 prompt 和交接说明。

`work/` 中的引擎、缓存、重复打包、旧版应用和超大调试日志仍保留本地，不进入 Git；它们不是运行源工程的依赖。

## 检查

首次导入：

```sh
godot --headless --editor --path outputs/StarportSquad --import
```

启动难度检查：

```sh
godot --headless --path outputs/StarportSquad --script ../../tests/difficulty_check.gd
```

创造模式检查：

```sh
godot --headless --path outputs/StarportSquad res://creator.tscn --quit-after 1000 -- --creator-check
```

完整自检入口为 `-- --self-test`；历史测试结果不代表当前版本全部回归通过。测试中应隔离用户存档，详见状态文档。

## 素材与权限

Noto Sans SC 字体授权见 `outputs/StarportSquad/assets/OFL-NotoSansSC.txt`。音乐和音效的生成代码保留在工程内。主菜单美术含 AI 生成图像。仓库已公开供浏览与协作，目前未指定项目代码和自有素材的开源许可证。第三方素材仍按各自许可证使用；历史 Godot 引擎参考代码保留其 MIT 许可声明。
