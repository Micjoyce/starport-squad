"""Install pinned official Godot Windows editor/templates for CI. Requires Windows."""
import hashlib
import os
from pathlib import Path
import urllib.request
import zipfile

ASSETS = {
    "Godot_v4.5-stable_win64.exe.zip": "303206071cb8be502cfa5b1e2b37b848c280347c03f78dcc2eb8a630857f7d10",
    "Godot_v4.5-stable_export_templates.tpz": "375d83b661794f91746d2dec9b569a99d4d24f85a70c4ec0068aafb18b551d53",
}
ROOT = Path(__file__).resolve().parents[1]


def main():
    if os.name != "nt":
        raise SystemExit("This installer configures Windows. Install Godot templates via the editor on other hosts.")
    downloads = ROOT / ".tools"
    downloads.mkdir(exist_ok=True)
    templates = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.5.stable"
    templates.mkdir(parents=True, exist_ok=True)
    for name, digest in ASSETS.items():
        archive = downloads / name
        print("Downloading official Godot asset:", name, flush=True)
        urllib.request.urlretrieve("https://github.com/godotengine/godot/releases/download/4.5-stable/" + name, archive)
        hasher = hashlib.sha256()
        with archive.open("rb") as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b""):
                hasher.update(chunk)
        if hasher.hexdigest() != digest:
            raise RuntimeError("SHA-256 mismatch: " + name)
        with zipfile.ZipFile(archive) as package:
            if name.endswith(".exe.zip"):
                # Fixed known paths only; never extract untrusted archive paths.
                for member in ("Godot_v4.5-stable_win64.exe", "Godot_v4.5-stable_win64_console.exe"):
                    (downloads / member).write_bytes(package.read(member))
            else:
                for member in ("windows_debug_x86_64.exe", "windows_release_x86_64.exe", "version.txt"):
                    (templates / member).write_bytes(package.read("templates/" + member))
        archive.unlink()


if __name__ == "__main__":
    main()
