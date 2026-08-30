"""Scene-specific, image-led qualification for the WP8.1 Start shell study.

This deliberately has no Pivot tracker dependency.  It preserves host-clock
limits and treats visual-state measurements separately from any timing claim.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter, deque
from pathlib import Path

from PIL import Image, ImageChops

VIEWPORT = [480, 800]
COLORS = {
    "accent_blue": (62, 101, 255), "music_green": (16, 124, 16),
    "office_orange": (235, 60, 0), "onenote_purple": (128, 57, 123),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def components(image: Image.Image, color: tuple[int, int, int], minimum: int = 100) -> list[dict]:
    """Return exact connected flat-color pixel extents, not semantic hitboxes."""
    pixels = image.convert("RGB").load(); width, height = image.size; seen = set(); found = []
    for y in range(height):
        for x in range(width):
            if (x, y) in seen or pixels[x, y] != color: continue
            q = deque([(x, y)]); seen.add((x, y)); n = 0; xs = []; ys = []
            while q:
                px, py = q.popleft(); n += 1; xs.append(px); ys.append(py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and pixels[nx, ny] == color:
                        seen.add((nx, ny)); q.append((nx, ny))
            if n >= minimum:
                found.append({"color": "#%02x%02x%02x" % color, "pixels": n,
                              "bbox_inclusive": [min(xs), min(ys), max(xs), max(ys)],
                              "rendered_extent_uncertainty_px": 1})
    return sorted(found, key=lambda item: item["pixels"], reverse=True)


def load_trial(trial: Path) -> dict:
    manifest_path = trial / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    with (trial / "frames.csv").open(encoding="utf-8") as file:
        rows = list(csv.DictReader(file))
    errors = list(manifest.get("errors", [])); hashes_valid = True
    changed = 0; previous = None
    for row in rows:
        frame = trial / "frames" / f"{int(row['frame']):06d}.png"
        if not frame.exists() or sha256(frame) != row["sha256"]:
            hashes_valid = False
            errors.append(f"missing-or-corrupt:{frame.name}")
        if previous and previous != row["sha256"]: changed += 1
        previous = row["sha256"]
    starts = [float(row["capture_start_ms"]) for row in rows]
    gaps = [b - a for a, b in zip(starts, starts[1:])]
    complete_events = (trial / "events.jsonl").exists()
    quality = {"hashes_valid": hashes_valid, "frame_count": len(rows), "changed_observations": changed,
               "max_capture_start_gap_ms": max(gaps, default=0), "events_file_present": complete_events,
               "classification": "rejected" if errors or not hashes_valid else "geometry-behavior-only",
               # A recorder can write byte-valid frames while reporting an
               # execution/precondition fault in its immutable manifest.  Such a
               # trial remains useful audit history, but it cannot qualify a
               # trajectory or duration claim.
               "trial_gate_passed": bool(not errors and hashes_valid and complete_events and changed >= 5 and max(gaps, default=0) <= 120),
               "scenario_motion_claim_eligible": False,
               "limits": ["Host capture intervals are not guest presentation timestamps.",
                          "No source element telemetry or font source record was used for type claims."]}
    if quality["trial_gate_passed"]:
        quality["classification"] = "single-trial-timing-gate-passed-not-a-claim"
    return {"manifest": manifest, "rows": rows, "quality": quality, "errors": errors}


def analyze(session: Path, output: Path) -> dict:
    if output.exists(): raise FileExistsError(f"fresh output required: {output}")
    output.mkdir(parents=True)
    trials = []
    for trial in sorted(session.iterdir()):
        if not trial.is_dir() or not (trial / "manifest.json").exists(): continue
        data = load_trial(trial); manifest = data["manifest"]
        first = trial / "frames" / "000000.png"
        geometry = []
        if first.exists() and manifest.get("resolution") == VIEWPORT:
            image = Image.open(first)
            for name, color in COLORS.items():
                geometry.extend([{**item, "role": name} for item in components(image, color)])
        passive_deltas = []
        if manifest["scenario"]["id"] == "live_tile_passive_flip":
            previous = None
            for row in data["rows"]:
                current = Image.open(trial / "frames" / f"{int(row['frame']):06d}.png").convert("RGB")
                if previous is not None:
                    bbox = ImageChops.difference(previous, current).getbbox()
                    if bbox: passive_deltas.append({"frame": int(row["frame"]), "changed_bbox": list(bbox)})
                previous = current
        entry = {"trial": trial.name, "source_frame": "frames/000000.png", "quality": data["quality"],
                 "manifest_sha256": sha256(trial / "manifest.json"), "geometry_components": geometry,
                 "passive_changed_frame_bboxes": passive_deltas[:100], "errors": data["errors"]}
        (output / f"{trial.name}.quality.json").write_text(json.dumps(entry, indent=2), encoding="utf-8")
        trials.append(entry)
    by_scenario: dict[str, list[dict]] = {}
    for entry in trials:
        scenario = entry["trial"].rsplit("_r", 1)[0]
        by_scenario.setdefault(scenario, []).append(entry)
    for scenario, entries in by_scenario.items():
        accepted = len(entries) >= 3 and all(e["quality"]["trial_gate_passed"] for e in entries)
        for entry in entries:
            entry["quality"]["scenario_motion_claim_eligible"] = accepted
            if not accepted:
                entry["quality"]["classification"] = "geometry-behavior-only"
                entry["quality"]["limits"].append("Three-repetition motion gate failed; no trajectory or duration claim is allowed.")
            entry["scenario_repeat_count"] = len(entries)
    result = {"schema_version": 1, "adapter_id": "start-screen-wp81-wvga", "session": session.name,
              "clock_semantics": "Frame intervals are host monotonic capture-call starts; delivered input receipts are separate host records, not guest presentation or physical touch time.",
              "measurement_scope": "Rendered pixel extents and image change regions only; no font-family/point-size source claim.",
              "trials": trials}
    (output / "measurements.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(); parser.add_argument("session", type=Path); parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(); result = analyze(args.session.resolve(), args.output.resolve()); print(json.dumps({"trials": len(result["trials"]), "output": str(args.output)}))

if __name__ == "__main__": main()
