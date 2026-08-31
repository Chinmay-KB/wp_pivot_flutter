"""Encode and inspect the deterministic launcher interaction demonstration."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--launcher", type=Path, required=True)
    parser.add_argument("--source-snapshot", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists(): raise SystemExit("video output must be fresh")
    frames = sorted(args.frames.glob("*.png"))
    if not frames: raise SystemExit("no PNG frames")
    args.output.mkdir(parents=True)
    concat = args.output / "frames.txt"
    concat.write_text("".join(f"file '{frame.as_posix()}'\n" for frame in frames), encoding="utf-8")
    video = args.output / "launcher-edit-interactions.mp4"
    encode = ["ffmpeg", "-y", "-r", "30", "-f", "concat", "-safe", "0", "-i", str(concat), "-fps_mode", "passthrough", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(video)]
    result = subprocess.run(encode, capture_output=True, text=True)
    if result.returncode: raise SystemExit(result.stderr)
    probe = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-show_streams", "-show_format", "-of", "json", str(video)], capture_output=True, text=True, check=True)
    decoded = json.loads(probe.stdout)
    if not decoded.get("streams") or int(decoded["streams"][0].get("nb_read_frames", "0")) <= 0:
        raise SystemExit("video did not decode to positive frames")
    if int(decoded["streams"][0]["nb_read_frames"]) != len(frames):
        raise SystemExit("encoded frame count does not preserve every source frame")
    revision = subprocess.run(["git", "rev-parse", "HEAD"], cwd=args.launcher, capture_output=True, text=True, check=True).stdout.strip()
    manifest = {
        "schema_version": 1,
        "source": "shipping launcher widget tree deterministic Flutter render",
        "launcher_revision": revision,
        "launcher_source_snapshot": {
            "path": str(args.source_snapshot),
            "sha256": digest(args.source_snapshot),
        },
        "viewport": [480, 800],
        "frame_schedule": {
            "source_capture_interval_ms": 28,
            "encoded_timeline": "30 fps deterministic presentation schedule; every source PNG retained without interpolation",
            "source_frame_count": len(frames),
            "decoded_frame_count": int(decoded["streams"][0]["nb_read_frames"]),
        },
        "scenarios": ["launch exit", "edit entry", "live reorder", "resize/reflow"],
        "video": {"path": video.name, "sha256": digest(video), "ffprobe": decoded},
        "limitations": ["Deterministic widget time verifies behavior/poses, not Android display smoothness or physical latency.", "Native WP8.1 source capture is host-clock sparse; this video does not claim an exact native curve."],
    }
    (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__": main()
