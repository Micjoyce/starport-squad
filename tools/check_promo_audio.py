"""Fail publication when a promo has a missing or effectively silent audio track."""
import argparse
import json
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("video")
    args = parser.parse_args()
    streams = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries",
        "format=duration,size:stream=codec_type,codec_name,sample_rate,channels",
        "-of", "json", args.video,
    ], text=True))
    if not any(s["codec_type"] == "audio" for s in streams["streams"]):
        raise SystemExit("FAIL: video has no audio stream")
    result = subprocess.run([
        "ffmpeg", "-hide_banner", "-i", args.video, "-vn", "-af", "volumedetect", "-f", "null", "-",
    ], capture_output=True, text=True, check=True)
    levels = {}
    for metric in ("mean_volume", "max_volume"):
        match = re.search(metric + r": ([-\d.]+|[-+]?inf) dB", result.stderr)
        if not match:
            raise SystemExit("FAIL: cannot measure audio level")
        levels[metric + "_db"] = float(match.group(1))
    # Detect an empty/silent capture, not merely the existence of an AAC container.
    if not levels["mean_volume_db"] > -55 or not levels["max_volume_db"] > -40:
        raise SystemExit("FAIL: audio is silent or effectively inaudible: " + str(levels))
    print(json.dumps({"result": "PASS", **streams, **levels}, indent=2))


if __name__ == "__main__":
    main()
