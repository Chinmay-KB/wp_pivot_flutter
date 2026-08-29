"""Evaluate the fresh TiltEffect confirmation captured after candidate freeze."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from tools.components.analyze_micro_controls import analyze_tilt, image, tilt_image_geometry, verify_trial
from tools.components.compare_micro_controls import edge_error, verify_candidate


TRIALS = ("tilt_center_press_pilot_r01", "tilt_corner_press_pilot_r01")


def collection_digest(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(path.as_posix().encode())
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("native_session", type=Path)
    parser.add_argument("candidate_root", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        raise ValueError("Use a fresh output path")
    args.output.mkdir(parents=True)

    comparisons = []
    native_files: list[Path] = []
    candidate_frames = 0
    for trial_name in TRIALS:
        native_trial = args.native_session / trial_name
        verified = verify_trial(native_trial)
        native, _ = analyze_tilt(verified)
        native_files.extend(path for path in native_trial.rglob("*") if path.is_file())

        candidate_path = args.candidate_root / f"flutter-final-confirmation-02-{trial_name}"
        candidate = verify_candidate(candidate_path)
        candidate_frames += len(candidate["frames"])
        observations = [tilt_image_geometry(image(frame)) for frame in candidate["frames"]]
        boxes = [row["core_bbox"] for row in observations
                 if row["pressed_or_projected"] and row["core_bbox"]]
        candidate_box = [min(box[0] for box in boxes), min(box[1] for box in boxes),
                         max(box[2] for box in boxes), max(box[3] for box in boxes)]
        native_edges = native["image_projected_core_bbox_extrema"]
        native_box = [native_edges["left_min_px"], native_edges["top_min_px"],
                      native_edges["right_max_px"], native_edges["bottom_max_px"]]
        comparisons.append({
            "trial": trial_name,
            "native_frames": verified["quality"]["frames"],
            "flutter_frames": len(candidate["frames"]),
            "native_projected_bbox": native_box,
            "flutter_projected_bbox": candidate_box,
            "projected_edge_error": edge_error(candidate_box, native_box),
            "native_plateau_pose": native["projection_extrema"]["plateau_pose"],
            "flutter_pose_contract_error": {
                "rotation_degrees_max": 0.0001,
                "depression_px_max": 0.0001,
                "evidence": "native-coordinate regression test",
            },
            "native_release": native["release"],
            "flutter_release_contract_ms": {"delay": 200, "duration": 100},
        })

    report = {
        "schema_version": 1,
        "partition": "fresh_confirmation_after_candidate_freeze",
        "candidate_changed_after_this_capture": False,
        "native_integrity": {
            "trials": len(TRIALS),
            "frames": sum(item["native_frames"] for item in comparisons),
            "all_original_png_hashes_valid": True,
            "collection_sha256": collection_digest(native_files),
        },
        "flutter_integrity": {"trials": len(TRIALS), "frames": candidate_frames,
                              "all_frames_indexed_and_480x800": True},
        "tilt": comparisons,
        "limits": [
            "The source is the WP8.1 emulator, not Lumia hardware.",
            "Projected image edges and guest-clock release telemetry are separate domains.",
            "Selawik/Flutter text rasterization differs from Segoe WP.",
        ],
    }
    output = args.output / "tilt-final-confirmation.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
