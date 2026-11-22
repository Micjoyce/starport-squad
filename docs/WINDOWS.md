# Windows 开发交接

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

Windows 导出：在 Godot 安装同版本 Export Templates，在 Project → Export 添加 Windows Desktop 预设，将产物导出到 Git 忽略的本地目录；当前仓库只有 macOS 预设。Windows 运行、输入、字体、音频与性能均需要重新验证。

## 给另一台电脑 Codex 的 prompt

> 请接续开发这个私有 Godot 4.5 Standard / GDScript 项目“星港小队”。先读根目录 AGENTS.md、README.md、docs/STATUS.md 和工程中的 CREATOR.md。唯一当前工程是 outputs/StarportSquad/project.godot，版本 0.16.0。保留中文 UI，科幻工业和太空主题，以适合小朋友的非血腥表现制作。先运行工程并建立 Windows 验证基线，检查五档及随机难度、战役检查点、创造模式、背包、装备、存档和基本战斗。修复真实报错，记录可复现步骤、机器配置和帧率。不要运行 archive 中历史生成器覆盖当前工程；不要把历史 483 项通过当作最新版回归结论。当前没有真实联机，没有玩家驾驶机甲，程序几何美术尚需升级。按正常商业游戏流程逐步提升操作、战斗反馈、关卡、UI、音频、美术和性能，每次先交付一段完整可玩体验并验证，再扩展功能。请区分已实现与计划，不宣称已经达到 3A 成品。持续把修改、测试证据和开发状态提交到当前私有仓库，未经要求不要更改可见性或公开素材。

## Codex 项目

在 Codex 点击添加项目/打开文件夹，选择仓库根目录 `starport-squad`（本机现有路径为原工作目录）。新对话可使用上述 prompt。根目录 AGENTS.md 保存持续开发约束。
