"""Package native and Flutter stagger poses without inventing a timing score."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _pair(native: Path, flutter: Path, output: Path, label: str) -> None:
    left = Image.open(native).convert("RGB")
    right = Image.open(flutter).convert("RGB")
    if left.size != (480, 800) or right.size != (480, 800):
        raise ValueError("stagger pose comparison requires 480x800 inputs")
    canvas = Image.new("RGB", (960, 800), "black")
    canvas.paste(left, (0, 0))
    canvas.paste(right, (480, 0))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 210, 24), fill="black")
    draw.rectangle((480, 0, 740, 24), fill="black")
    draw.text((8, 6), f"WP8.1 emulator — {label}", fill="white")
    draw.text((488, 6), f"Flutter pose sweep — {label}", fill="white")
    canvas.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--native-entry", type=Path, required=True)
    parser.add_argument("--flutter-entry", type=Path, required=True)
    parser.add_argument("--native-exit", type=Path, required=True)
    parser.add_argument("--flutter-exit", type=Path, required=True)
    parser.add_argument("--flutter-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError(f"fresh output required: {args.output}")
    args.output.mkdir(parents=True)
    _pair(
        args.native_entry,
        args.flutter_entry,
        args.output / "entry-side-by-side.png",
        "entry",
    )
    _pair(
        args.native_exit,
        args.flutter_exit,
        args.output / "exit-side-by-side.png",
        "exit",
    )
    report = {
        "schema_version": 1,
        "adapter_id": "wp81-wvga-stagger-pose-inspection-v1",
        "status": "qualitative-inspection-evidence",
        "native_entry": str(args.native_entry.resolve()),
        "native_entry_sha256": _sha256(args.native_entry),
        "flutter_entry": str(args.flutter_entry.resolve()),
        "flutter_entry_sha256": _sha256(args.flutter_entry),
        "native_exit": str(args.native_exit.resolve()),
        "native_exit_sha256": _sha256(args.native_exit),
        "flutter_exit": str(args.flutter_exit.resolve()),
        "flutter_exit_sha256": _sha256(args.flutter_exit),
        "flutter_manifest": str(args.flutter_manifest.resolve()),
        "flutter_manifest_sha256": _sha256(args.flutter_manifest),
        "observed_correspondence": [
            "right-edge Y-axis perspective pose",
            "rightmost items lead exit",
            "lower items lag exit and settle earlier on entry",
        ],
        "not_qualified": [
            "exact progress-to-native-time mapping",
            "exact curve or duration",
            "pixel-level transformed polygon equivalence",
        ],
        "passed": None,
    }
    (args.output / "report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    print(json.dumps({"status": report["status"], "output": str(args.output)}))


if __name__ == "__main__":
    main()
