"""Compare held-out Flutter micro-control replays with immutable WP8.1 data."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import statistics

from PIL import Image

from tools.components.analyze_micro_controls import (
    determinate_geometry,
    image,
    indeterminate_components,
    slider_geometry,
    tilt_image_geometry,
)


SCENARIOS = (
    "slider_tap_high_pilot_r03",
    "slider_drag_full_pilot_r03",
    "progress_animation_pilot_r03",
    "tilt_center_press_pilot_r03",
    "tilt_corner_press_pilot_r03",
)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as source:
        return list(csv.DictReader(source))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def candidate_dir(root: Path, scenario: str) -> Path:
    result = root / f"flutter-heldout-02-{scenario}"
    if not result.is_dir():
        raise ValueError(f"Missing candidate replay: {result}")
    return result


def verify_candidate(path: Path) -> dict:
    manifest = json.loads((path / "manifest.json").read_text(encoding="utf-8"))
    frame_rows = read_csv(path / "frames.csv")
    frames = sorted((path / "frames").glob("*.png"))
    if len(frames) != len(frame_rows) or len(frames) != manifest["frame_count"]:
        raise ValueError(f"Candidate frame membership mismatch: {path}")
    digests = []
    for index, frame in enumerate(frames):
        if frame.name != f"{index:06d}.png":
            raise ValueError(f"Candidate frame index mismatch: {frame}")
        with Image.open(frame) as source:
            if source.size != (480, 800):
                raise ValueError(f"Candidate resolution mismatch: {frame}")
        digests.append(sha256(frame))
    return {"path": path, "manifest": manifest, "frames": frames,
            "frame_rows": frame_rows, "digests": digests}


def edge_error(candidate: list[int], reference: list[int]) -> dict:
    errors = [abs(a - b) for a, b in zip(candidate, reference)]
    return {"per_edge_px": errors, "maximum_px": max(errors)}


def progress_alignment(native_session: Path, native_analysis: Path,
                       candidate: dict) -> dict:
    native_trial = native_session / "progress_animation_pilot_r03"
    native_frames = read_csv(native_trial / "frames.csv")
    native_marks = [row for row in read_csv(native_analysis / "indeterminate-marks.csv")
                    if row["trial"] == "progress_animation_pilot_r03"]
    by_frame: dict[int, list[float]] = {}
    for row in native_marks:
        by_frame.setdefault(int(row["source_frame"]), []).append(float(row["center_x_px"]))
    native_observations = [
        (float(row["capture_end_ms"]), sorted(by_frame.get(int(row["frame"]), [])))
        for row in native_frames
    ]
    origin = native_observations[0][0]
    native_observations = [(time - origin, marks) for time, marks in native_observations]
    candidate_observations = [
        (float(row["t_ms"]), sorted(mark["center_x_px"] for mark in
         indeterminate_components(image(candidate["frames"][index]))))
        for index, row in enumerate(candidate["frame_rows"])
    ]

    def nearest(target: float) -> list[float]:
        return min(candidate_observations, key=lambda item: abs(item[0] - target))[1]

    best = None
    for offset in range(0, 1001):
        absolute_errors: list[float] = []
        cardinality_error = 0
        compared = 0
        for time, native_centers in native_observations:
            candidate_centers = nearest(time + offset)
            cardinality_error += abs(len(native_centers) - len(candidate_centers))
            if len(native_centers) == len(candidate_centers) and native_centers:
                absolute_errors.extend(abs(a - b) for a, b in
                                       zip(native_centers, candidate_centers))
                compared += 1
        mae = statistics.fmean(absolute_errors) if absolute_errors else math.inf
        score = mae + cardinality_error * 30 / len(native_observations)
        result = (score, offset, mae, cardinality_error, compared,
                  len(absolute_errors), max(absolute_errors, default=None))
        if best is None or result < best:
            best = result
    assert best is not None
    return {
        "phase_alignment": "single offset fitted against held-out images for reporting only; candidate was already frozen",
        "candidate_offset_ms": best[1],
        "aligned_center_mae_px": best[2],
        "aligned_center_max_error_px": best[6],
        "cardinality_error_sum": best[3],
        "frames_with_equal_nonzero_cardinality": best[4],
        "matched_mark_observations": best[5],
        "native_interpolation": "none; nearest acquired native/candidate frames only",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("native_session", type=Path)
    parser.add_argument("native_analysis", type=Path)
    parser.add_argument("candidate_root", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        raise ValueError("Use a fresh output path")
    args.output.mkdir(parents=True)

    summary = json.loads((args.native_analysis / "summary.json").read_text(encoding="utf-8"))
    candidates = {name: verify_candidate(candidate_dir(args.candidate_root, name))
                  for name in SCENARIOS}

    slider_results = []
    native_slider = {row["trial"]: row for row in summary["slider"]["measurements"]
                     if row["partition"] == "held_out"}
    for scenario in SCENARIOS[:2]:
        candidate = candidates[scenario]
        geometry = slider_geometry(image(candidate["frames"][-1]))
        changes = [item["slider"] for item in candidate["manifest"]["selection_or_commands"]
                   if isinstance(item, dict) and "slider" in item]
        reference = native_slider[scenario]
        slider_results.append({
            "trial": scenario,
            "native_final_value": reference["final_telemetry_value"],
            "flutter_final_value": changes[-1],
            "final_value_abs_error": abs(changes[-1] - reference["final_telemetry_value"]),
            "flutter_image_value": geometry["image_value"],
            "image_value_abs_error": abs(geometry["image_value"] - reference["final_image_value"]),
            "track_edges": edge_error(geometry["track_bbox"], reference["final_geometry"]["track_bbox"]),
            "thumb_edges": edge_error(geometry["thumb_bbox"], reference["final_geometry"]["thumb_bbox"]),
        })

    progress_candidate = candidates["progress_animation_pilot_r03"]
    progress_geometry = determinate_geometry(image(progress_candidate["frames"][0]))
    native_progress = next(row for row in summary["determinate_progress"]["measurements"]
                           if row["trial"] == "progress_animation_pilot_r03")
    progress = {
        "determinate_track_edges": edge_error(
            progress_geometry["track_bbox"], native_progress["image"]["track_bbox"]),
        "determinate_fill_edges": edge_error(
            progress_geometry["fill_bbox"], native_progress["image"]["fill_bbox"]),
        "indeterminate": progress_alignment(
            args.native_session, args.native_analysis, progress_candidate),
        "native_period_lower_bound_ms": 3452.2311,
        "flutter_configured_period_ms": 4500,
        "period_error_ms": None,
        "period_claim": "not scored; native period is right-censored",
    }

    tilt_results = []
    native_tilt = {row["trial"]: row for row in summary["tilt"]["held_out_r03"]}
    for scenario in SCENARIOS[3:]:
        candidate = candidates[scenario]
        observations = [tilt_image_geometry(image(frame)) for frame in candidate["frames"]]
        projected = [row for row in observations if row["pressed_or_projected"]]
        boxes = [row["core_bbox"] for row in projected if row["core_bbox"]]
        extrema = None if not boxes else [
            min(box[0] for box in boxes), min(box[1] for box in boxes),
            max(box[2] for box in boxes), max(box[3] for box in boxes),
        ]
        native_box = native_tilt[scenario]["image_projected_core_bbox_extrema"]
        reference = [native_box["left_min_px"], native_box["top_min_px"],
                     native_box["right_max_px"], native_box["bottom_max_px"]]
        tilt_results.append({
            "trial": scenario,
            "flutter_projected_bbox_extrema": extrema,
            "native_projected_bbox_extrema": reference,
            "projected_edge_error": None if extrema is None else edge_error(extrema, reference),
            "formula_pose_error": {"rotation_degrees_max": 0.0001, "depression_px_max": 0.0001,
                                   "evidence": "native-coordinate regression test"},
            "flutter_release_contract_ms": {"delay": 200, "duration": 100},
            "native_release_first_sample_ms": {
                "delay": native_tilt[scenario]["release"]["delay_first_changed_sample_ms"],
                "duration": native_tilt[scenario]["release"]["duration_first_changed_to_first_rest_ms"],
            },
        })

    report = {
        "schema_version": 1,
        "partition": "held_out_r03",
        "candidate_changed_after_held_out": False,
        "native_collection_sha256": summary["integrity"]["raw_collection_sha256"],
        "candidate_integrity": {
            "trials": len(candidates),
            "frames": sum(len(item["frames"]) for item in candidates.values()),
            "all_frames_indexed_and_480x800": True,
        },
        "slider": slider_results,
        "progress": progress,
        "tilt": tilt_results,
        "limits": [
            "WP8.1 emulator evidence is not Lumia hardware evidence.",
            "Native host acquisition and guest Stopwatch clocks are not aligned.",
            "Selawik and Flutter rasterization differ from native Segoe WP.",
            "Progress phase is aligned only for trajectory reporting; its exact native loop period is unknown.",
        ],
    }
    output = args.output / "heldout-comparison.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
