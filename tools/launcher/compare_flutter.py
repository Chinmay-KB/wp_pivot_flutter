"""Compare a Flutter Start-grid fixture with a held-out WP8.1 frame.

This adapter deliberately measures only evidenced flat-color tile bounds. It
does not score caller-supplied icons/text, infer typography, or treat a widget
test render as live Android performance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

VIEWPORT = (480, 800)
TILE_EXPECTATIONS = (
    ("phone", "#3e65ff", (24, 56, 233, 265)),
    ("messaging", "#3e65ff", (246, 56, 344, 154)),
    ("browser", "#3e65ff", (357, 56, 455, 154)),
    ("mail", "#3e65ff", (246, 167, 344, 265)),
    ("store", "#3e65ff", (357, 167, 455, 265)),
    ("music", "#107c10", (246, 278, 344, 376)),
    ("games", "#107c10", (357, 278, 455, 376)),
    ("office", "#eb3c00", (246, 389, 344, 487)),
    ("notes", "#80397b", (357, 389, 455, 487)),
    ("calendar", "#3e65ff", (24, 500, 233, 709)),
    ("kids", "#3e65ff", (246, 500, 455, 709)),
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rgb(value: str) -> tuple[int, int, int]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def component_bbox(
    image: Image.Image,
    color: tuple[int, int, int],
    expected: tuple[int, int, int, int],
    search_radius: int = 3,
) -> tuple[int, int, int, int] | None:
    """Find the color component whose top-left is nearest the expected bound."""
    pixels = image.convert("RGB").load()
    width, height = image.size
    left, top, _, _ = expected
    seeds = []
    for y in range(max(0, top - search_radius), min(height, top + search_radius + 1)):
        for x in range(max(0, left - search_radius), min(width, left + search_radius + 1)):
            if pixels[x, y] == color:
                seeds.append((abs(x - left) + abs(y - top), x, y))
    if not seeds:
        return None
    _, start_x, start_y = min(seeds)
    queue = deque([(start_x, start_y)])
    seen = {(start_x, start_y)}
    xs = []
    ys = []
    while queue:
        x, y = queue.popleft()
        xs.append(x)
        ys.append(y)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (
                0 <= nx < width
                and 0 <= ny < height
                and (nx, ny) not in seen
                and pixels[nx, ny] == color
            ):
                seen.add((nx, ny))
                queue.append((nx, ny))
    if len(seen) < 1000:
        return None
    return min(xs), min(ys), max(xs), max(ys)


def compare(
    native_frame: Path,
    flutter_frame: Path,
    flutter_manifest: Path,
    output: Path,
    tolerance_px: int = 1,
) -> dict:
    if output.exists():
        raise FileExistsError(f"fresh output required: {output}")
    output.mkdir(parents=True)
    native = Image.open(native_frame).convert("RGB")
    flutter = Image.open(flutter_frame).convert("RGB")
    if native.size != VIEWPORT or flutter.size != VIEWPORT:
        raise ValueError(
            f"expected {VIEWPORT} frames, got native={native.size} flutter={flutter.size}"
        )
    manifest = json.loads(flutter_manifest.read_text(encoding="utf-8"))
    if manifest.get("resolution") != [480, 800]:
        raise ValueError("Flutter manifest does not declare the 480x800 adapter viewport")
    results = []
    for name, color_hex, expected in TILE_EXPECTATIONS:
        color = rgb(color_hex)
        native_bbox = component_bbox(native, color, expected)
        flutter_bbox = component_bbox(flutter, color, expected)
        native_error = (
            None
            if native_bbox is None
            else max(abs(actual - target) for actual, target in zip(native_bbox, expected))
        )
        flutter_error = (
            None
            if flutter_bbox is None
            else max(abs(actual - target) for actual, target in zip(flutter_bbox, expected))
        )
        results.append(
            {
                "name": name,
                "color": color_hex,
                "expected_bbox_inclusive": list(expected),
                "native_bbox_inclusive": list(native_bbox) if native_bbox else None,
                "flutter_bbox_inclusive": list(flutter_bbox) if flutter_bbox else None,
                "native_max_edge_error_px": native_error,
                "flutter_max_edge_error_px": flutter_error,
                "passed": native_error is not None
                and native_error <= 1
                and flutter_error is not None
                and flutter_error <= tolerance_px,
            }
        )
    passed = all(item["passed"] for item in results)
    report = {
        "schema_version": 1,
        "adapter_id": "start-screen-wp81-wvga-rest-geometry-v1",
        "native_source": "Microsoft WP8.1 WVGA emulator held-out frame",
        "flutter_source": "deterministic Flutter widget render",
        "native_frame": str(native_frame.resolve()),
        "native_sha256": sha256(native_frame),
        "flutter_frame": str(flutter_frame.resolve()),
        "flutter_sha256": sha256(flutter_frame),
        "flutter_manifest": str(flutter_manifest.resolve()),
        "flutter_manifest_sha256": sha256(flutter_manifest),
        "tolerance_px": tolerance_px,
        "measurement": "inclusive flat-color connected-component bounds",
        "claims": [
            "resting tile surface geometry only",
            "no icon, text, font, motion, runtime, or physical-latency claim",
        ],
        "tiles": results,
        "passed": passed,
    }
    (output / "report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    preview = Image.new("RGB", (960, 800), "black")
    preview.paste(native, (0, 0))
    preview.paste(flutter, (480, 0))
    draw = ImageDraw.Draw(preview)
    for item in results:
        color = "#00ff80" if item["passed"] else "#ff3355"
        if item["native_bbox_inclusive"]:
            draw.rectangle(item["native_bbox_inclusive"], outline=color, width=1)
        if item["flutter_bbox_inclusive"]:
            shifted = item["flutter_bbox_inclusive"].copy()
            shifted[0] += 480
            shifted[2] += 480
            draw.rectangle(shifted, outline=color, width=1)
    preview.save(output / "side-by-side.png")
    if not passed:
        failures = ", ".join(item["name"] for item in results if not item["passed"])
        raise ValueError(f"tile geometry comparison failed: {failures}")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--native-frame", type=Path, required=True)
    parser.add_argument("--flutter-frame", type=Path, required=True)
    parser.add_argument("--flutter-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tolerance-px", type=int, default=1)
    args = parser.parse_args()
    result = compare(
        args.native_frame,
        args.flutter_frame,
        args.flutter_manifest,
        args.output,
        args.tolerance_px,
    )
    print(json.dumps({"passed": result["passed"], "output": str(args.output)}))


if __name__ == "__main__":
    main()
