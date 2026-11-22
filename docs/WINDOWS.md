# Windows 游戏与开发交接

直接游玩：在私有仓库 [0.16.1 Release](https://github.com/Micjoyce/starport-squad/releases/tag/v0.16.1) 下载 `StarportSquad-Windows-x64-0.16.1.zip`，完整解压后双击 `StarportSquad.exe`。

使用有私有仓库读取权限的 GitHub 账号：

```powershell
git clone https://github.com/micjoyce/starport-squad.git
cd starport-squad
```

安装官方 Godot 4.5 Standard，在项目管理器导入 `outputs/StarportSquad/project.godot`。无需 macOS 的 `work/` 目录。首次导入会重新生成 `.godot/`。

启动命令（Godot 不在 PATH 时填写可执行文件绝对路径）：

```powershell
godot --editor --path outputs/StarportSquad
godot --path outputs/StarportSquad
```

## Windows 游戏打包

工程同时保留 macOS Universal 和 Windows Desktop x86_64 导出预设。安装 Godot 4.5 Standard 及相同版本 Export Templates 后，在仓库根目录执行：

```powershell
python tools/build_windows.py --godot "C:\Tools\Godot_v4.5-stable_win64_console.exe" --verify
```

`--godot` 也可以填写 PATH 中的命令。脚本先导入素材、导出 exe 和独立 pck，再运行 Windows 导出包检查，最后生成：

- `dist/StarportSquad-Windows-x64-0.16.1.zip`
- `dist/SHA256SUMS-Windows.txt`
- `dist/windows-platform-check.log`

玩家解压整个 ZIP 后双击 `StarportSquad.exe`，无需安装 Godot。exe 和 pck 必须保留在同一目录。中文字体、音效、音乐已包含。需要支持 OpenGL 3.3 的显卡驱动；这是未签名开发包。

macOS/Linux 也能运行同一脚本交叉导出 Windows，但应省略 `--verify`，它必须在 Windows 执行。macOS 导出预设继续可用。

## 自动构建与验证

`.github/workflows/windows.yml` 在 Windows runner 中安装 SHA-256 校验过的官方 Godot 4.5 编辑器及模板，构建后直接运行 Windows exe 的 `--platform-check`。每次主分支相关代码修改后自动执行，也可在 GitHub Actions 手动运行。下载 `StarportSquad-Windows-x64` artifact 后解压外层，再解压其中游戏 ZIP。

检查涵盖难度界面、五档及随机选择、关键输入映射、打包字体与音乐、进入战斗、第一/第三人称、模拟帧、存档原子写入与读取，以及创造模式战斗、升级、锻造和保存读取。检查使用独立临时存档，不覆盖日常档。发布版本不依赖会在 release 中失效的 GDScript assert。

这是无窗口功能检查；人工画面、鼠标手感、真实声音输出和 GPU 性能仍需在玩家 Windows 电脑上验证。用户存档由 Godot 写入 `%APPDATA%\Godot\app_userdata` 下的游戏目录，系统间不会自动同步。

官方参考：[Windows 导出](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html)、[命令行导出](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html)。

## 给另一台电脑 Codex 的 prompt

> 请接续开发这个私有 Godot 4.5 Standard / GDScript 项目“星港小队”。先读根目录 AGENTS.md、README.md、docs/STATUS.md 和工程中的 CREATOR.md。唯一当前工程是 outputs/StarportSquad/project.godot，版本 0.16.1。保留中文 UI，科幻工业和太空主题，以适合小朋友的非血腥表现制作。先运行工程并建立 Windows 验证基线，检查五档及随机难度、战役检查点、创造模式、背包、装备、存档和基本战斗。修复真实报错，记录可复现步骤、机器配置和帧率。不要运行 archive 中历史生成器覆盖当前工程；不要把历史 483 项通过当作最新版回归结论。当前没有真实联机，没有玩家驾驶机甲，程序几何美术尚需升级。按正常商业游戏流程逐步提升操作、战斗反馈、关卡、UI、音频、美术和性能，每次先交付一段完整可玩体验并验证，再扩展功能。请区分已实现与计划，不宣称已经达到 3A 成品。持续把修改、测试证据和开发状态提交到当前私有仓库，未经要求不要更改可见性或公开素材。

## Codex 项目

在 Codex 点击添加项目/打开文件夹，选择仓库根目录 `starport-squad`（本机现有路径为原工作目录）。新对话可使用上述 prompt。根目录 AGENTS.md 保存持续开发约束。
