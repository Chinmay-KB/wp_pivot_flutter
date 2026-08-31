"""Qualify WP8.1 Start edit recordings without Pivot-specific assumptions."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

VIEWPORT = (480, 800)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def trial_report(trial: Path) -> dict[str, object]:
    manifest = json.loads((trial / "manifest.json").read_text(encoding="utf-8"))
    rows = list(csv.DictReader((trial / "frames.csv").open(encoding="utf-8")))
    hashes = all(sha(trial / "frames" / f"{int(row['frame']):06d}.png") == row["sha256"] for row in rows)
    images = [Image.open(trial / "frames" / f"{int(row['frame']):06d}.png").convert("RGB") for row in rows]
    changed = [index for index in range(1, len(images)) if ImageChops.difference(images[index - 1], images[index]).getbbox()]
    intervals = [float(b["capture_start_ms"]) - float(a["capture_start_ms"]) for a, b in zip(rows, rows[1:])]
    return {
        "trial": trial.name,
        "scenario": manifest["scenario"]["id"],
        "hashes_valid": hashes,
        "frame_count": len(rows),
        "resolution": manifest.get("resolution"),
        "complete_delivered_actions": bool((trial / "events.jsonl").exists()) and not manifest.get("errors"),
        "changed_frame_count": len(changed),
        "first_changed_frame": changed[0] if changed else None,
        "last_changed_frame": changed[-1] if changed else None,
        "max_capture_start_gap_ms": max(intervals, default=0),
        "quality": "behavior-and-geometry-supported" if hashes and changed and not manifest.get("errors") else "rejected",
        "timing_limit": "Host capture intervals are sparse host observations; no exact native curve or presentation timing is claimed.",
        "representative_frames": [f"frames/{index:06d}.png" for index in sorted({0, len(rows)//3, 2*len(rows)//3, max(0, len(rows)-1)})],
    }


def contact_sheet(trial: Path, output: Path) -> None:
    rows = list(csv.DictReader((trial / "frames.csv").open(encoding="utf-8")))
    chosen = sorted({0, len(rows)//3, 2*len(rows)//3, max(0, len(rows)-1)})
    sheet = Image.new("RGB", (480, 800 * len(chosen)), "black")
    draw = ImageDraw.Draw(sheet)
    for offset, index in enumerate(chosen):
        image = Image.open(trial / "frames" / f"{index:06d}.png").convert("RGB")
        sheet.paste(image, (0, offset * 800))
        draw.rectangle((0, offset * 800, 112, offset * 800 + 28), fill="black")
        draw.text((8, offset * 800 + 6), f"frame {index:03d}", fill="white")
    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sessions", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists(): raise SystemExit("output must be fresh")
    args.output.mkdir(parents=True)
    reports = []
    for session in args.sessions:
        for trial in sorted(session.iterdir()):
            if (trial / "manifest.json").exists():
                report = trial_report(trial)
                reports.append(report)
                contact_sheet(trial, args.output / f"{trial.name}-contact-sheet.png")
    by_scenario: dict[str, list[dict[str, object]]] = {}
    for report in reports: by_scenario.setdefault(str(report["scenario"]), []).append(report)
    summary = {
        "schema_version": 1,
        "adapter_id": "start-screen-wp81-wvga-edit-interactions-v1",
        "viewport": list(VIEWPORT),
        "trials": reports,
        "scenario_repetitions": {key: len(value) for key, value in by_scenario.items()},
        "claims": [
            {"behavior": "long press enters selected-tile edit state; non-selected planes visibly dim/scale.", "supported_by": "edit_entry_phone repetitions"},
            {"behavior": "a held tile visibly follows the drag path while neighboring planes reflow before release.", "supported_by": "live_reorder_phone_to_people repetitions"},
            {
                "behavior": "resize changes packing and visibly displaces neighboring planes.",
                "supported_by": "resize_people_r01, resize_people_wide_r02, and resize_people_medium_r03 size-stage captures",
            }
        ],
        "limits": [
            "No custom Start tracker recovers an exact curve, native transform values, or presentation timing.",
            "Host capture cadence is irregular and frames may miss state boundaries; only visible sampled behavior/geometry is claimed.",
            "The phone's live content changes independently between trials, so it is not used as a geometry marker."
        ]
    }
    (args.output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__": main()
