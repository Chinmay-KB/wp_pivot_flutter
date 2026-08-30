"""Compare app-list and alphabet geometry with held-out WP8.1 frames."""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

VIEWPORT = (480, 800)
ACCENT = "#3e65ff"
NATIVE_DISABLED = "#1f1f1f"
FLUTTER_DISABLED = "#202020"


@dataclass(frozen=True)
class Expectation:
    name: str
    bounds: tuple[int, int, int, int]
    native_color: str = ACCENT
    flutter_color: str = ACCENT


APP_LIST = tuple(
    Expectation(name, bounds)
    for name, bounds in (
        ("header-a", (86, 57, 147, 118)),
        ("alarms-icon", (86, 131, 147, 192)),
        ("header-b", (86, 205, 147, 266)),
        ("battery-icon", (86, 279, 147, 340)),
        ("header-c", (86, 353, 147, 414)),
        ("calculator-icon", (86, 427, 147, 488)),
        ("calendar-icon", (86, 501, 147, 562)),
        ("camera-icon", (86, 575, 147, 636)),
        ("cortana-icon", (86, 649, 147, 710)),
        ("header-d", (86, 723, 147, 784)),
    )
)

ALPHABET_LABELS = (
    "#",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "globe",
)
ALPHABET_ENABLED = {
    "a",
    "b",
    "c",
    "d",
    "f",
    "g",
    "h",
    "i",
    "m",
    "n",
    "o",
    "p",
    "s",
    "t",
    "v",
    "w",
}
ALPHABET = tuple(
    Expectation(
        name=f"cell-{label}",
        bounds=(
            24 + (index % 4) * 111,
            19 + (index // 4) * 111,
            122 + (index % 4) * 111,
            117 + (index // 4) * 111,
        ),
        native_color=ACCENT if label in ALPHABET_ENABLED else NATIVE_DISABLED,
        flutter_color=ACCENT if label in ALPHABET_ENABLED else FLUTTER_DISABLED,
    )
    for index, label in enumerate(ALPHABET_LABELS)
)

SURFACES = {"app-list": APP_LIST, "alphabet": ALPHABET}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _rgb(value: str) -> tuple[int, int, int]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def _component_bbox(
    image: Image.Image,
    color: tuple[int, int, int],
    expected: tuple[int, int, int, int],
    search_radius: int = 2,
) -> tuple[int, int, int, int] | None:
    pixels = image.load()
    width, height = image.size
    left, top, _, _ = expected
    seeds: list[tuple[int, int, int]] = []
    for y in range(max(0, top - search_radius), min(height, top + search_radius + 1)):
        for x in range(max(0, left - search_radius), min(width, left + search_radius + 1)):
            if pixels[x, y] == color:
                seeds.append((abs(x - left) + abs(y - top), x, y))
    if not seeds:
        return None
    _, start_x, start_y = min(seeds)
    queue = deque([(start_x, start_y)])
    seen = {(start_x, start_y)}
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (
                0 <= nx < width
                and 0 <= ny < height
                and (nx, ny) not in seen
                and pixels[nx, ny] == color
            ):
                seen.add((nx, ny))
                queue.append((nx, ny))
    if len(seen) < 100:
        return None
    xs = [point[0] for point in seen]
    ys = [point[1] for point in seen]
    return min(xs), min(ys), max(xs), max(ys)


def compare(
    surface: str,
    native_frame: Path,
    flutter_frame: Path,
    flutter_manifest: Path,
    output: Path,
    tolerance_px: int = 1,
) -> dict:
    if surface not in SURFACES:
        raise ValueError(f"unknown surface: {surface}")
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
        raise ValueError("Flutter manifest does not declare the 480x800 viewport")

    results = []
    for item in SURFACES[surface]:
        native_bbox = _component_bbox(native, _rgb(item.native_color), item.bounds)
        flutter_bbox = _component_bbox(flutter, _rgb(item.flutter_color), item.bounds)
        native_error = (
            None
            if native_bbox is None
            else max(abs(a - b) for a, b in zip(native_bbox, item.bounds))
        )
        flutter_error = (
            None
            if flutter_bbox is None
            else max(abs(a - b) for a, b in zip(flutter_bbox, item.bounds))
        )
        results.append(
            {
                "name": item.name,
                "expected_bbox_inclusive": list(item.bounds),
                "native_bbox_inclusive": list(native_bbox) if native_bbox else None,
                "flutter_bbox_inclusive": list(flutter_bbox) if flutter_bbox else None,
                "native_color": item.native_color,
                "flutter_color": item.flutter_color,
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
        "adapter_id": f"start-screen-wp81-wvga-{surface}-geometry-v1",
        "native_source": "Microsoft WP8.1 WVGA emulator held-out frame",
        "flutter_source": "deterministic Flutter widget render",
        "surface": surface,
        "native_frame": str(native_frame.resolve()),
        "native_sha256": _sha256(native_frame),
        "flutter_frame": str(flutter_frame.resolve()),
        "flutter_sha256": _sha256(flutter_frame),
        "flutter_manifest": str(flutter_manifest.resolve()),
        "flutter_manifest_sha256": _sha256(flutter_manifest),
        "tolerance_px": tolerance_px,
        "measurement": "inclusive flat-color connected-component bounds",
        "claims": [
            f"resting {surface} surface geometry only",
            "no icon, text, font, motion, runtime, or physical-latency claim",
        ],
        "items": results,
        "passed": passed,
    }
    (output / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

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
        raise ValueError(f"{surface} geometry comparison failed: {failures}")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--surface", choices=sorted(SURFACES), required=True)
    parser.add_argument("--native-frame", type=Path, required=True)
    parser.add_argument("--flutter-frame", type=Path, required=True)
    parser.add_argument("--flutter-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tolerance-px", type=int, default=1)
    args = parser.parse_args()
    result = compare(
        args.surface,
        args.native_frame,
        args.flutter_frame,
        args.flutter_manifest,
        args.output,
        args.tolerance_px,
    )
    print(json.dumps({"passed": result["passed"], "output": str(args.output)}))


if __name__ == "__main__":
    main()
