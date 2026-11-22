"""Export and package the shared Godot project for Windows x86_64.

Requires Godot 4.5 Standard and its official 4.5.stable export templates.
Works on Windows, macOS and Linux; --verify requires a Windows host.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "outputs" / "StarportSquad"


def run(command, **kwargs):
    print("Running:", " ".join(map(str, command)), flush=True)
    return subprocess.run(list(map(str, command)), check=True, **kwargs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--verify", action="store_true", help="Run the exported game checks on Windows")
    args = parser.parse_args()
    if args.verify and os.name != "nt":
        parser.error("--verify must run on Windows; cross-export is supported without it")
    godot = shutil.which(args.godot)
    if not godot:
        parser.error("Godot executable not found; provide --godot with its full path")
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    if not version.startswith("4.5.stable.") or ".mono." in version:
        parser.error("Use Godot 4.5 stable Standard to match the installed export templates")
    output = ROOT / "dist" / "windows"
    output.mkdir(parents=True, exist_ok=True)
    # Remove only our previous export to prevent a failed export packaging stale binaries.
    for name in ("StarportSquad.exe", "StarportSquad.pck"):
        (output / name).unlink(missing_ok=True)
    run([godot, "--headless", "--editor", "--path", PROJECT, "--import"], timeout=300)
    run([godot, "--headless", "--path", PROJECT, "--export-release", "Windows Desktop", output / "StarportSquad.exe"], timeout=300)
    for name in ("StarportSquad.exe", "StarportSquad.pck"):
        if not (output / name).is_file() or not (output / name).stat().st_size:
            raise RuntimeError("Missing export: " + name)
    shutil.copyfile(PROJECT / "assets" / "OFL-NotoSansSC.txt", output / "OFL-NotoSansSC.txt")
    (output / "README.txt").write_text(
        "星港小队 Starport Squad 0.16.1 - Windows x64 开发预览\n\n"
        "解压整个文件夹后双击 StarportSquad.exe，无需安装 Godot。\n"
        "请保持 StarportSquad.pck 和 exe 在同一目录。\n"
        "需要支持 OpenGL 3.3 的显卡和驱动。\n"
        "WASD 移动 / 鼠标瞄准射击 / 空格跳跃 / R 换弹 / V 切换人称 / Esc 暂停。\n"
        "存档保存在 %APPDATA%\\Godot\\app_userdata 下的游戏目录。\n"
        "这是未签名的开发预览版本；不是最终商业发行版。\n",
        encoding="utf-8-sig",
    )
    if args.verify:
        log = ROOT / "dist" / "windows-platform-check.log"
        result = run([output / "StarportSquad.exe", "--headless", "--log-file", log, "--", "--platform-check"], timeout=120)
        text = log.read_text(encoding="utf-8", errors="replace")
        print(text)
        if "PLATFORM CHECKS PASSED" not in text or "SCRIPT ERROR" in text or "PLATFORM CHECK FAILED" in text:
            raise RuntimeError("Exported Windows checks did not pass; see " + str(log))
    archive = ROOT / "dist" / "StarportSquad-Windows-x64-0.16.1.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
        for name in ("StarportSquad.exe", "StarportSquad.pck", "OFL-NotoSansSC.txt", "README.txt"):
            package.write(output / name, "StarportSquad/" + name)
    checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
    (ROOT / "dist" / "SHA256SUMS-Windows.txt").write_text(checksum + "  " + archive.name + "\n", encoding="ascii")
    print("Created:", archive)


if __name__ == "__main__":
    main()
