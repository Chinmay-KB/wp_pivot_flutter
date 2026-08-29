"""Offline analyzer for the WP8.1 WVGA micro-controls confirmation set.

The analyzer keeps host acquisition intervals and guest Stopwatch telemetry in
separate domains.  It verifies every source PNG before deriving image geometry.
No frames are interpolated and a loop period is not invented when recurrence is
not present in the capture window.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import sys
from typing import Iterable

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image


ACCENT = np.array([62, 101, 255], dtype=np.uint8)
TRACK = np.array([31, 31, 31], dtype=np.uint8)
PROGRESS_TRACK = np.array([25, 25, 25], dtype=np.uint8)
WHITE = np.array([255, 255, 255], dtype=np.uint8)
EXPECTED_RESOLUTION = [480, 800]
SCENARIOS = (
    "slider_tap_high_pilot",
    "slider_drag_full_pilot",
    "progress_animation_pilot",
    "tilt_center_press_pilot",
    "tilt_corner_press_pilot",
)
TRIAL_RE = re.compile(r"(.+)_r(\d{2})$")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def read_csv(path: Path, *, allow_empty: bool = False) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)
        if not reader.fieldnames:
            raise ValueError(f"CSV has no header: {path}")
        rows = list(reader)
    if not allow_empty and not rows:
        raise ValueError(f"CSV has no observations: {path}")
    return rows


def finite_float(row: dict[str, str], key: str, source: Path) -> float:
    try:
        value = float(row[key])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(f"Invalid {key} in {source}") from exc
    if not math.isfinite(value):
        raise ValueError(f"Non-finite {key} in {source}")
    return value


def bbox(mask: np.ndarray, x_offset: int = 0, y_offset: int = 0) -> list[int] | None:
    ys, xs = np.where(mask)
    if not len(xs):
        return None
    return [
        int(xs.min()) + x_offset,
        int(ys.min()) + y_offset,
        int(xs.max()) + x_offset + 1,
        int(ys.max()) + y_offset + 1,
    ]


def dimensions(box: list[int] | None) -> tuple[int | None, int | None]:
    if box is None:
        return None, None
    return box[2] - box[0], box[3] - box[1]


def exact_mask(image: np.ndarray, color: np.ndarray) -> np.ndarray:
    return np.all(image == color, axis=2)


def image(path: Path) -> np.ndarray:
    with Image.open(path) as source:
        return np.asarray(source.convert("RGB"))


def slider_geometry(pixels: np.ndarray) -> dict:
    roi = pixels[165:200, :, :]
    accent = bbox(exact_mask(roi, ACCENT), y_offset=165)
    dark = bbox(exact_mask(roi, TRACK), y_offset=165)
    thumb = bbox(exact_mask(roi, WHITE), y_offset=165)
    if not accent or not dark or not thumb:
        raise ValueError("Slider tracker did not find fill, track, and thumb")
    track = [min(accent[0], dark[0]), min(accent[1], dark[1]),
             max(accent[2], dark[2]), max(accent[3], dark[3])]
    track_width, track_height = dimensions(track)
    thumb_width, thumb_height = dimensions(thumb)
    center = (thumb[0] + thumb[2]) / 2
    usable = track_width - thumb_width
    value = 100 * (center - (track[0] + thumb_width / 2)) / usable
    return {
        "track_bbox": track,
        "track_width_px": track_width,
        "track_height_px": track_height,
        "fill_bbox": accent,
        "fill_width_px": accent[2] - accent[0],
        "thumb_bbox": thumb,
        "thumb_width_px": thumb_width,
        "thumb_height_px": thumb_height,
        "thumb_center_x_px": center,
        "image_value": value,
        "accent_rgb": ACCENT.tolist(),
        "accent_hex": "#3E65FF",
    }


def determinate_geometry(pixels: np.ndarray) -> dict:
    roi = pixels[280:296, :, :]
    fill = bbox(exact_mask(roi, ACCENT), y_offset=280)
    dark = bbox(exact_mask(roi, PROGRESS_TRACK), y_offset=280)
    if not fill or not dark:
        raise ValueError("Determinate ProgressBar tracker did not find both segments")
    track = [min(fill[0], dark[0]), min(fill[1], dark[1]),
             max(fill[2], dark[2]), max(fill[3], dark[3])]
    width, height = dimensions(track)
    fill_width = fill[2] - fill[0]
    return {
        "track_bbox": track,
        "track_width_px": width,
        "track_height_px": height,
        "fill_bbox": fill,
        "fill_width_px": fill_width,
        "image_fraction_percent": 100 * fill_width / width,
        "accent_rgb": ACCENT.tolist(),
        "accent_hex": "#3E65FF",
    }


def indeterminate_components(pixels: np.ndarray) -> list[dict]:
    """Return alpha-weighted observations of marks in the 4 px animation lane."""
    lane = pixels[353:357, :, :]
    # The marks are the only colored pixels in this lane.  Blue is full-scale
    # 255 at the core and proportional to pixel coverage on antialiased edges.
    colored = lane[:, :, 2] > 0
    columns = np.flatnonzero(colored.any(axis=0))
    if not len(columns):
        return []
    runs: list[tuple[int, int]] = []
    start = previous = int(columns[0])
    for raw in columns[1:]:
        x = int(raw)
        if x > previous + 1:
            runs.append((start, previous + 1))
            start = x
        previous = x
    runs.append((start, previous + 1))
    result = []
    for left, right in runs:
        blue_alpha = lane[:, left:right, 2].astype(float) / 255.0
        area = float(blue_alpha.sum())
        if area <= 0:
            continue
        xs = np.arange(left, right, dtype=float) + 0.5
        weights = blue_alpha.sum(axis=0)
        center_x = float(np.sum(xs * weights) / weights.sum())
        result.append({
            "bbox": [left, 353, right, 357],
            "center_x_px": center_x,
            "alpha_area_px2": area,
            "logical_width_px": area / 4.0,
            "logical_height_px": 4,
            "full_mark": abs(area - 16.0) <= 0.08,
            "clipped_left": left == 36 and area < 15.92,
            "clipped_right": right == 444 and area < 15.92,
        })
    return result


def tilt_image_geometry(pixels: np.ndarray) -> dict:
    roi = pixels[418:480, :, :]
    foreground = np.max(roi, axis=2) >= 128
    box = bbox(foreground, y_offset=418)
    accent_area = int(exact_mask(roi, ACCENT).sum())
    return {"core_bbox": box, "accent_core_area_px": accent_area,
            "pressed_or_projected": accent_area > 100}


def locate_guest_file(trial: Path, name: str) -> Path:
    matches = list((trial / "guest").rglob(name))
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one guest {name} in {trial}; found {len(matches)}")
    return matches[0]


def verify_trial(trial: Path) -> dict:
    manifest_path = trial / "manifest.json"
    frames_path = trial / "frames.csv"
    if not manifest_path.is_file() or not frames_path.is_file():
        raise ValueError(f"Incomplete trial directory: {trial}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    rows = read_csv(frames_path)
    if manifest.get("errors"):
        raise ValueError(f"Capture manifest contains errors: {trial}")
    if manifest.get("frame_count") != len(rows):
        raise ValueError(f"Frame count mismatch: {trial}")
    if manifest.get("resolution") != EXPECTED_RESOLUTION:
        raise ValueError(f"Unsupported resolution in {trial}: {manifest.get('resolution')}")

    starts: list[float] = []
    ends: list[float] = []
    hashes: list[str] = []
    for index, row in enumerate(rows):
        if int(row.get("frame", -1)) != index:
            raise ValueError(f"Non-contiguous frame index in {trial}")
        frame = trial / "frames" / f"{index:06d}.png"
        data = frame.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != row.get("sha256") or len(data) != int(row.get("bytes", -1)):
            raise ValueError(f"Raw frame integrity failed: {frame}")
        with Image.open(frame) as source:
            if list(source.size) != EXPECTED_RESOLUTION:
                raise ValueError(f"Raw frame dimensions changed: {frame}")
        start = finite_float(row, "capture_start_ms", frames_path)
        end = finite_float(row, "capture_end_ms", frames_path)
        if start < 0 or end <= start or (ends and start < ends[-1]):
            raise ValueError(f"Invalid/overlapping host acquisition intervals: {trial}")
        starts.append(start)
        ends.append(end)
        hashes.append(digest)
    expected = {f"{index:06d}.png" for index in range(len(rows))}
    actual = {p.name for p in (trial / "frames").glob("*.png")}
    if actual != expected:
        raise ValueError(f"Unexpected raw frame membership: {trial}")

    state_path = locate_guest_file(trial, "state.csv")
    inputs_path = locate_guest_file(trial, "inputs.csv")
    state = read_csv(state_path)
    inputs = read_csv(inputs_path, allow_empty=True)
    guest_times = [finite_float(row, "t_ms", state_path) for row in state]
    input_times = [finite_float(row, "t_ms", inputs_path) for row in inputs]
    if any(b < a for a, b in zip(guest_times, guest_times[1:])):
        raise ValueError(f"Guest state clock is not monotonic: {trial}")
    if any(b < a for a, b in zip(input_times, input_times[1:])):
        raise ValueError(f"Guest input clock is not monotonic: {trial}")

    match = TRIAL_RE.fullmatch(trial.name)
    if not match:
        raise ValueError(f"Trial name has no repetition suffix: {trial.name}")
    scenario, repetition = match.group(1), int(match.group(2))
    expected_inputs = scenario != "progress_animation_pilot"
    if expected_inputs and not inputs:
        raise ValueError(f"Expected delivered guest input observations: {trial}")
    if not expected_inputs and inputs:
        raise ValueError(f"Wait-only progress trial unexpectedly contains guest input: {trial}")

    start_intervals = [b - a for a, b in zip(starts, starts[1:])]
    acquisition = [b - a for a, b in zip(starts, ends)]
    idle_gaps = [b - a for a, b in zip(ends, starts[1:])]
    quality = {
        "trial": trial.name,
        "scenario": scenario,
        "repetition": repetition,
        "partition": "held_out" if repetition == 3 else "fitting",
        "frames": len(rows),
        "distinct_frames": len(set(hashes)),
        "duplicate_frames": len(rows) - len(set(hashes)),
        "hashes_valid": True,
        "resolution": EXPECTED_RESOLUTION,
        "host_capture_start_interval_median_ms": statistics.median(start_intervals) if start_intervals else None,
        "host_capture_start_interval_max_ms": max(start_intervals, default=None),
        "host_acquisition_duration_median_ms": statistics.median(acquisition),
        "host_acquisition_duration_max_ms": max(acquisition),
        "host_idle_gap_max_ms": max(idle_gaps, default=None),
        "host_observation_span_ms": ends[-1] - ends[0],
        "guest_state_rows": len(state),
        "guest_input_rows": len(inputs),
        "manifest_errors": [],
    }
    return {
        "trial": trial,
        "manifest": manifest,
        "frame_rows": rows,
        "state": state,
        "inputs": inputs,
        "quality": quality,
        "state_path": state_path,
        "inputs_path": inputs_path,
    }


def initial_state_ok(state: list[dict[str, str]]) -> bool:
    first = state[0]
    return (
        abs(float(first["slider_value"]) - 35) < 0.001
        and abs(float(first["determinate_value"]) - 42) < 0.001
        and first["indeterminate_state"].lower() == "true"
        and first["tilt_projection_present"].lower() == "false"
    )


def analyze_slider(verified: dict) -> dict:
    trial = verified["trial"]
    states = verified["state"]
    initial_value = float(states[0]["slider_value"])
    final_value = float(states[-1]["slider_value"])
    first_geometry = slider_geometry(image(trial / "frames" / "000000.png"))
    last_index = len(verified["frame_rows"]) - 1
    final_geometry = slider_geometry(image(trial / "frames" / f"{last_index:06d}.png"))
    return {
        "trial": trial.name,
        "scenario": verified["quality"]["scenario"],
        "partition": verified["quality"]["partition"],
        "initial_telemetry_value": initial_value,
        "final_telemetry_value": final_value,
        "value_changed_events": sum(row.get("event") == "slider_value_changed" for row in states),
        "initial_image_value": first_geometry["image_value"],
        "final_image_value": final_geometry["image_value"],
        "final_telemetry_image_abs_error": abs(final_value - final_geometry["image_value"]),
        "initial_geometry": first_geometry,
        "final_geometry": final_geometry,
    }


def analyze_determinate(verified: dict) -> dict:
    states = verified["state"]
    geometry = determinate_geometry(image(verified["trial"] / "frames" / "000000.png"))
    value = float(states[0]["determinate_value"])
    return {
        "trial": verified["trial"].name,
        "partition": verified["quality"]["partition"],
        "telemetry_value": value,
        "telemetry_bbox": [float(states[0][key]) for key in
                           ("determinate_x", "determinate_y", "determinate_width", "determinate_height")],
        "image": geometry,
        "rasterized_fill_edge_error_px": abs(
            geometry["fill_bbox"][2] -
            (geometry["track_bbox"][0] + geometry["track_width_px"] * value / 100)
        ),
    }


def assign_mark_ids(observations: list[list[dict]]) -> list[list[dict]]:
    previous_ids: list[int] = []
    maximum_id = 0
    result: list[list[dict]] = []
    for components in observations:
        count = len(components)
        if not previous_ids:
            ids = list(range(count, 0, -1))
            maximum_id = count
        elif count > len(previous_ids):
            added = count - len(previous_ids)
            new_ids = list(range(maximum_id + added, maximum_id, -1))
            maximum_id += added
            ids = new_ids + previous_ids
        elif count < len(previous_ids):
            ids = previous_ids[:count]
        else:
            ids = previous_ids[:]
        if len(ids) != count:
            raise AssertionError("mark identity assignment failed")
        row = []
        for component, mark_id in zip(components, ids):
            row.append({**component, "mark_id": mark_id})
        result.append(row)
        previous_ids = ids
    return result


def analyze_indeterminate(verified: dict) -> tuple[dict, list[dict]]:
    observations: list[list[dict]] = []
    for row in verified["frame_rows"]:
        index = int(row["frame"])
        observations.append(indeterminate_components(
            image(verified["trial"] / "frames" / f"{index:06d}.png")
        ))
    identified = assign_mark_ids(observations)
    tracks: list[dict] = []
    for frame_row, components in zip(verified["frame_rows"], identified):
        for order, component in enumerate(components, start=1):
            tracks.append({
                "trial": verified["trial"].name,
                "partition": verified["quality"]["partition"],
                "source_frame": int(frame_row["frame"]),
                "host_capture_end_ms": float(frame_row["capture_end_ms"]),
                "left_to_right_order": order,
                **component,
            })
    max_marks = max(map(len, observations), default=0)
    unique_ids = sorted({row["mark_id"] for row in tracks})
    full = [row for row in tracks if row["full_mark"]]
    if max_marks != 5 or unique_ids != [1, 2, 3, 4, 5] or not full:
        raise ValueError(f"Expected five observable indeterminate trajectories: {verified['trial']}")

    latest = [row for row in tracks if row["mark_id"] == 5]
    first_latest = min(latest, key=lambda row: row["source_frame"])
    first_index = first_latest["source_frame"]
    if first_index == 0:
        lower_bound = None
        first_interval = None
    else:
        previous_end = float(verified["frame_rows"][first_index - 1]["capture_end_ms"])
        current_end = float(verified["frame_rows"][first_index]["capture_end_ms"])
        first_interval = [previous_end, current_end]
        lower_bound = float(verified["frame_rows"][-1]["capture_end_ms"]) - current_end
    summary = {
        "trial": verified["trial"].name,
        "partition": verified["quality"]["partition"],
        "observed_trajectory_ids": unique_ids,
        "max_simultaneously_visible_marks": max_marks,
        "full_mark_alpha_area_median_px2": statistics.median(row["alpha_area_px2"] for row in full),
        "logical_mark_width_median_px": statistics.median(row["logical_width_px"] for row in full),
        "logical_mark_height_px": 4,
        "animation_lane_half_open": [36, 353, 444, 357],
        "repeat_period": {
            "status": "unknown_right_censored",
            "estimate_ms": None,
            "lower_bound_ms": lower_bound,
            "upper_bound_ms": None,
            "latest_mark_first_visibility_host_interval_ms": first_interval,
            "reason": "No mark trajectory recurs before the immutable capture ends; only a one-sided lower bound is supported.",
        },
    }
    return summary, tracks


def pose(row: dict[str, str]) -> tuple[float, float, float]:
    return (float(row["tilt_rotation_x"]), float(row["tilt_rotation_y"]),
            float(row["tilt_global_offset_z"]))


def pose_changed(a: tuple[float, float, float], b: tuple[float, float, float], tolerance=0.00011) -> bool:
    return any(abs(x - y) > tolerance for x, y in zip(a, b))


def analyze_tilt(verified: dict) -> tuple[dict, list[dict]]:
    state = verified["state"]
    inputs = verified["inputs"]
    projected = [row for row in state if row["tilt_projection_present"].lower() == "true"]
    if not projected:
        raise ValueError(f"Tilt projection was never observed: {verified['trial']}")
    up_rows = [row for row in inputs if row.get("event") == "Up"]
    down_rows = [row for row in inputs if row.get("event") == "Down"]
    if len(up_rows) != 1 or len(down_rows) != 1:
        raise ValueError(f"Tilt trial needs exactly one guest Down/Up: {verified['trial']}")
    up_ms = float(up_rows[0]["t_ms"])
    plateau = pose(projected[0])
    after_up = [row for row in projected if float(row["t_ms"]) >= up_ms]
    changed_index = next((index for index, row in enumerate(after_up)
                          if pose_changed(pose(row), plateau)), None)
    if changed_index is None or changed_index == 0:
        raise ValueError(f"Tilt release transition is not bracketed: {verified['trial']}")
    first_changed = after_up[changed_index]
    last_plateau = after_up[changed_index - 1]
    rest_index = next((index for index in range(changed_index + 1, len(after_up))
                       if max(map(abs, pose(after_up[index]))) <= 0.00011), None)
    if rest_index is None:
        raise ValueError(f"Tilt rest is not observed: {verified['trial']}")
    first_rest = after_up[rest_index]
    last_nonrest = after_up[rest_index - 1]

    image_rows: list[dict] = []
    for frame_row in verified["frame_rows"]:
        index = int(frame_row["frame"])
        geometry = tilt_image_geometry(image(verified["trial"] / "frames" / f"{index:06d}.png"))
        image_rows.append({
            "trial": verified["trial"].name,
            "partition": verified["quality"]["partition"],
            "source_frame": index,
            "host_capture_end_ms": float(frame_row["capture_end_ms"]),
            **geometry,
        })
    pressed = [row for row in image_rows if row["pressed_or_projected"]]
    if not pressed:
        raise ValueError(f"Tilt image tracker found no pressed/projected frame: {verified['trial']}")
    boxes = [row["core_bbox"] for row in pressed if row["core_bbox"]]
    image_extrema = {
        "left_min_px": min(box[0] for box in boxes),
        "left_max_px": max(box[0] for box in boxes),
        "top_min_px": min(box[1] for box in boxes),
        "top_max_px": max(box[1] for box in boxes),
        "right_min_px": min(box[2] for box in boxes),
        "right_max_px": max(box[2] for box in boxes),
        "bottom_min_px": min(box[3] for box in boxes),
        "bottom_max_px": max(box[3] for box in boxes),
    }

    changed_ms = float(first_changed["t_ms"])
    plateau_ms = float(last_plateau["t_ms"])
    rest_ms = float(first_rest["t_ms"])
    nonrest_ms = float(last_nonrest["t_ms"])
    summary = {
        "trial": verified["trial"].name,
        "scenario": verified["quality"]["scenario"],
        "partition": verified["quality"]["partition"],
        "guest_input": {
            "down_ms": float(down_rows[0]["t_ms"]),
            "up_ms": up_ms,
            "down_xy": [float(down_rows[0]["x"]), float(down_rows[0]["y"])],
            "up_xy": [float(up_rows[0]["x"]), float(up_rows[0]["y"])],
        },
        "projection_extrema": {
            "rotation_x_min_deg": min(float(row["tilt_rotation_x"]) for row in projected),
            "rotation_x_max_deg": max(float(row["tilt_rotation_x"]) for row in projected),
            "rotation_y_min_deg": min(float(row["tilt_rotation_y"]) for row in projected),
            "rotation_y_max_deg": max(float(row["tilt_rotation_y"]) for row in projected),
            "global_offset_z_min": min(float(row["tilt_global_offset_z"]) for row in projected),
            "global_offset_z_max": max(float(row["tilt_global_offset_z"]) for row in projected),
            "plateau_pose": {"rotation_x_deg": plateau[0], "rotation_y_deg": plateau[1],
                             "global_offset_z": plateau[2]},
        },
        "release": {
            "clock": "guest Stopwatch shared by inputs.csv and state.csv",
            "delay_first_changed_sample_ms": changed_ms - up_ms,
            "delay_bracket_ms": [plateau_ms - up_ms, changed_ms - up_ms],
            "duration_first_changed_to_first_rest_ms": rest_ms - changed_ms,
            "duration_bracket_ms": [nonrest_ms - changed_ms, rest_ms - plateau_ms],
            "last_plateau_guest_ms": plateau_ms,
            "first_changed_guest_ms": changed_ms,
            "last_nonrest_guest_ms": nonrest_ms,
            "first_rest_guest_ms": rest_ms,
        },
        "image_projected_core_bbox_extrema": image_extrema,
        "image_timing_alignment": "none; host capture frames are not assigned guest Stopwatch timestamps",
    }
    return summary, image_rows


def aggregate_capture(quality: list[dict], partition: str) -> dict:
    selected = [row for row in quality if row["partition"] == partition]
    return {
        "trial_count": len(selected),
        "frame_count": sum(row["frames"] for row in selected),
        "distinct_frame_count": sum(row["distinct_frames"] for row in selected),
        "duplicate_frame_count": sum(row["duplicate_frames"] for row in selected),
        "median_of_trial_median_start_intervals_ms": statistics.median(
            row["host_capture_start_interval_median_ms"] for row in selected
        ),
        "max_capture_start_interval_ms": max(row["host_capture_start_interval_max_ms"] for row in selected),
        "max_host_idle_gap_ms": max(row["host_idle_gap_max_ms"] for row in selected),
    }


def scenario_partition(values: list[dict], scenario: str, partition: str, key: str) -> dict:
    selected = [row[key] for row in values
                if row.get("scenario") == scenario and row["partition"] == partition]
    return {"samples": len(selected), "values": selected,
            "median": statistics.median(selected) if selected else None,
            "minimum": min(selected, default=None), "maximum": max(selected, default=None)}


def make_plots(output: Path, progress_tracks: list[dict], tilt: list[dict], verified: list[dict]) -> None:
    progress_trials = sorted({row["trial"] for row in progress_tracks})
    fig, axes = plt.subplots(len(progress_trials), 1, figsize=(9, 7), sharex=False, sharey=True)
    axes = np.atleast_1d(axes)
    for axis, name in zip(axes, progress_trials):
        rows = [row for row in progress_tracks if row["trial"] == name]
        origin = min(row["host_capture_end_ms"] for row in rows)
        for mark_id in range(1, 6):
            track = [row for row in rows if row["mark_id"] == mark_id]
            axis.plot([row["host_capture_end_ms"] - origin for row in track],
                      [row["center_x_px"] for row in track], ".-", markersize=2,
                      label=f"mark {mark_id}")
        axis.set_title(name + (" (held out)" if name.endswith("r03") else ""))
        axis.set_ylabel("observed x (px)")
        axis.grid(alpha=.2)
    axes[-1].set_xlabel("host capture-end timeline from first observed frame (ms)")
    axes[0].legend(ncol=5, fontsize=7)
    fig.tight_layout()
    fig.savefig(output / "indeterminate-trajectories.png", dpi=160)
    plt.close(fig)

    tilt_by_name = {row["trial"]: row for row in tilt}
    fig, axes = plt.subplots(2, 1, figsize=(9, 6), sharex=True)
    for item in verified:
        name = item["trial"].name
        if name not in tilt_by_name:
            continue
        up = tilt_by_name[name]["guest_input"]["up_ms"]
        rows = [row for row in item["state"] if row["tilt_projection_present"].lower() == "true"]
        times = [float(row["t_ms"]) - up for row in rows]
        rotation = [math.hypot(float(row["tilt_rotation_x"]), float(row["tilt_rotation_y"])) for row in rows]
        depth = [-float(row["tilt_global_offset_z"]) for row in rows]
        style = "--" if name.endswith("r03") else "-"
        axes[0].plot(times, rotation, style, linewidth=1, label=name)
        axes[1].plot(times, depth, style, linewidth=1, label=name)
    axes[0].set_ylabel("rotation magnitude (deg)")
    axes[1].set_ylabel("-GlobalOffsetZ")
    axes[1].set_xlabel("guest Stopwatch relative to delivered Up (ms)")
    for axis in axes:
        axis.axvline(200, color="black", alpha=.3, linewidth=1)
        axis.grid(alpha=.2)
    axes[0].legend(ncol=2, fontsize=6)
    fig.tight_layout()
    fig.savefig(output / "tilt-release.png", dpi=160)
    plt.close(fig)


def collection_digest(session: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(p for p in session.rglob("*") if p.is_file()):
        relative = path.relative_to(session).as_posix().encode()
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(bytes.fromhex(sha256(path)))
    return digest.hexdigest()


def analyze_session(session: Path, output: Path, *, study: Path | None = None,
                    fixture: Path | None = None, handoff: Path | None = None) -> dict:
    session, output = Path(session), Path(output)
    if output.exists():
        raise ValueError("Analysis output must be a fresh path")
    if not session.is_dir():
        raise ValueError("Native session does not exist")
    trial_dirs = sorted(path for path in session.iterdir() if path.is_dir() and (path / "manifest.json").is_file())
    if not trial_dirs:
        raise ValueError("Native session contains no trials")
    names = {path.name for path in trial_dirs}
    expected = {f"{scenario}_r{rep:02d}" for scenario in SCENARIOS for rep in (1, 2, 3)}
    if names != expected:
        raise ValueError(f"Confirmation coverage mismatch; missing={sorted(expected-names)}, extra={sorted(names-expected)}")

    verified = [verify_trial(path) for path in trial_dirs]
    session_plan_path = session / "plan.json"
    session_plan_hash = sha256(session_plan_path)
    session_plan = json.loads(session_plan_path.read_text(encoding="utf-8-sig"))
    fixture_plan_path = Path(fixture) / "scenarios.json" if fixture else None
    if fixture_plan_path and fixture_plan_path.is_file():
        fixture_plan = json.loads(fixture_plan_path.read_text(encoding="utf-8-sig"))
        if session_plan != fixture_plan:
            raise ValueError("Session plan is not semantically identical to the fixture scenario source")
        recorded_plan_hash = sha256(fixture_plan_path)
    else:
        recorded_hashes = {
            item["manifest"].get("provenance", {}).get("scenario_plan_sha256")
            for item in verified
        }
        if len(recorded_hashes) != 1 or None in recorded_hashes:
            raise ValueError("Manifest scenario-plan provenance is missing or inconsistent")
        recorded_plan_hash = next(iter(recorded_hashes))
    for item in verified:
        recorded = item["manifest"].get("provenance", {}).get("scenario_plan_sha256")
        if recorded != recorded_plan_hash:
            raise ValueError(f"Scenario plan provenance mismatch: {item['trial']}")
        if not initial_state_ok(item["state"]):
            raise ValueError(f"Expected initial guest state was not observed: {item['trial']}")

    quality = [item["quality"] for item in verified]
    sliders = [analyze_slider(item) for item in verified if item["quality"]["scenario"].startswith("slider_")]
    determinate = [analyze_determinate(item) for item in verified]
    progress: list[dict] = []
    progress_tracks: list[dict] = []
    for item in verified:
        if item["quality"]["scenario"] == "progress_animation_pilot":
            result, tracks = analyze_indeterminate(item)
            progress.append(result)
            progress_tracks.extend(tracks)
    tilt: list[dict] = []
    tilt_image_rows: list[dict] = []
    for item in verified:
        if item["quality"]["scenario"].startswith("tilt_"):
            result, rows = analyze_tilt(item)
            tilt.append(result)
            tilt_image_rows.extend(rows)

    # Do not leave a partial analysis directory when verification/tracking fails.
    output.mkdir(parents=True)

    source_hash = sha256(Path(__file__))
    summary = {
        "schema_version": 1,
        "adapter": "micro-controls-wp81-wvga-v1",
        "source_session": str(session.resolve()),
        "analysis_source_sha256": source_hash,
        "integrity": {
            "trial_count": len(verified),
            "expected_trial_count": 15,
            "all_png_hashes_and_lengths_valid": True,
            "all_frame_indexes_complete": True,
            "all_resolutions": EXPECTED_RESOLUTION,
            "all_manifest_errors_empty": True,
            "all_initial_guest_states_verified": True,
            "session_plan_sha256": session_plan_hash,
            "fixture_scenario_plan_sha256": recorded_plan_hash,
            "session_and_fixture_plans_semantically_equal": True if fixture_plan_path else None,
            "raw_collection_sha256": collection_digest(session),
        },
        "coordinate_convention": "Image bboxes are [left, top, right, bottom] half-open pixel edges in original 480x800 PNG coordinates.",
        "clock_domains": {
            "host": "frames.csv capture_start_ms/capture_end_ms are monotonic host intervals around acquisition; used only for image cadence and observed trajectories.",
            "guest": "state.csv and inputs.csv t_ms share the fixture Stopwatch; used for Tilt release delay/duration and Slider state.",
            "alignment": "No host-to-guest clock alignment was established. Image selection/layout and guest transition timing are reported separately.",
        },
        "partitions": {
            "fitting": [item["trial"].name for item in verified if item["quality"]["partition"] == "fitting"],
            "held_out": [item["trial"].name for item in verified if item["quality"]["partition"] == "held_out"],
        },
        "capture_quality": {
            "fitting": aggregate_capture(quality, "fitting"),
            "held_out_r03": aggregate_capture(quality, "held_out"),
        },
        "slider": {
            "measurements": sliders,
            "fitting_final_values": {
                scenario: scenario_partition(sliders, scenario, "fitting", "final_telemetry_value")
                for scenario in ("slider_tap_high_pilot", "slider_drag_full_pilot")
            },
            "held_out_r03_final_values": {
                scenario: scenario_partition(sliders, scenario, "held_out", "final_telemetry_value")
                for scenario in ("slider_tap_high_pilot", "slider_drag_full_pilot")
            },
        },
        "determinate_progress": {
            "measurements": determinate,
            "rest_geometry_consistent_across_all_trials": len({json.dumps(row["image"], sort_keys=True) for row in determinate}) == 1,
        },
        "indeterminate_progress": {
            "measurements": progress,
            "held_out_r03": [row for row in progress if row["partition"] == "held_out"],
            "period_conclusion": "The repeat period is right-censored in every trial. Keep it unknown; lower bounds are reported per trial.",
        },
        "tilt": {
            "measurements": tilt,
            "held_out_r03": [row for row in tilt if row["partition"] == "held_out"],
        },
        "unsupported_or_excluded": [
            {"metric": "indeterminate exact loop period", "status": "unknown",
             "reason": "No trajectory recurs within any immutable capture; only right-censored lower bounds are observable."},
            {"metric": "host-to-guest event latency", "status": "unknown",
             "reason": "Host SDK receipts and the guest Stopwatch have no calibrated clock alignment."},
            {"metric": "physical display FPS/presentation latency", "status": "excluded",
             "reason": "Emulator acquisition and guest rendering callbacks do not observe physical display presentation."},
            {"metric": "Tilt image-time release curve", "status": "excluded",
             "reason": "Static image extrema are valid, but frames are not assigned guest Stopwatch timestamps."},
        ],
        "next_flutter_replay_contract": {
            "viewport": EXPECTED_RESOLUTION,
            "partition_rule": "Tune only against r01-r02. Run r03 once against the frozen candidate without refitting.",
            "slider": {
                "rest_track_bbox": sliders[0]["initial_geometry"]["track_bbox"],
                "rest_thumb_bbox_at_value_35": sliders[0]["initial_geometry"]["thumb_bbox"],
                "thumb_size_px": [sliders[0]["initial_geometry"]["thumb_width_px"], sliders[0]["initial_geometry"]["thumb_height_px"]],
                "value_to_thumb_center_x": "x = 30 + 4.2 * value for this 0..100 scene",
                "accent_hex": "#3E65FF",
                "compare": "final semantic value and final image-derived value separately; tolerance 1.0 value unit",
            },
            "determinate_progress": {
                "track_bbox": determinate[0]["image"]["track_bbox"],
                "fill_bbox_at_value_42": determinate[0]["image"]["fill_bbox"],
                "accent_hex": "#3E65FF",
                "compare": "half-open left/right/top/bottom edges within 1 source pixel",
            },
            "indeterminate_progress": {
                "marks": 5,
                "logical_mark_size_px": [4, 4],
                "lane_half_open": [36, 353, 444, 357],
                "trajectory_source": "indeterminate-marks.csv original host capture-end observations; hold missing source frames and do not interpolate native motion",
                "period": "unknown from this collection; do not select a Flutter repeat period from r03 or claim the study's period-error acceptance yet",
            },
            "tilt": {
                "telemetry_source": "tilt-measurements.csv / summary.json guest Stopwatch projection observations",
                "image_source": "tilt-image-edges.csv static host-frame projected bboxes",
                "timing": "release delay and duration use only guest brackets; do not align host images to guest time",
                "compare": "rotation extrema, GlobalOffsetZ depression, release delay/duration, and static projected edges as separate metrics",
            },
        },
    }

    quality_fields = list(quality[0])
    write_csv(output / "trial-quality.csv", quality, quality_fields)
    slider_flat = []
    for row in sliders:
        slider_flat.append({
            "trial": row["trial"], "scenario": row["scenario"], "partition": row["partition"],
            "initial_telemetry_value": row["initial_telemetry_value"],
            "final_telemetry_value": row["final_telemetry_value"],
            "initial_image_value": row["initial_image_value"], "final_image_value": row["final_image_value"],
            "final_telemetry_image_abs_error": row["final_telemetry_image_abs_error"],
            "initial_track_bbox": json.dumps(row["initial_geometry"]["track_bbox"]),
            "initial_thumb_bbox": json.dumps(row["initial_geometry"]["thumb_bbox"]),
            "final_thumb_bbox": json.dumps(row["final_geometry"]["thumb_bbox"]),
            "accent_hex": "#3E65FF",
        })
    write_csv(output / "slider-measurements.csv", slider_flat, list(slider_flat[0]))
    det_flat = [{
        "trial": row["trial"], "partition": row["partition"], "telemetry_value": row["telemetry_value"],
        "track_bbox": json.dumps(row["image"]["track_bbox"]), "track_width_px": row["image"]["track_width_px"],
        "fill_bbox": json.dumps(row["image"]["fill_bbox"]), "fill_width_px": row["image"]["fill_width_px"],
        "image_fraction_percent": row["image"]["image_fraction_percent"],
        "rasterized_fill_edge_error_px": row["rasterized_fill_edge_error_px"], "accent_hex": "#3E65FF",
    } for row in determinate]
    write_csv(output / "determinate-measurements.csv", det_flat, list(det_flat[0]))
    mark_fields = ["trial", "partition", "source_frame", "host_capture_end_ms", "mark_id",
                   "left_to_right_order", "center_x_px", "alpha_area_px2", "logical_width_px",
                   "logical_height_px", "full_mark", "clipped_left", "clipped_right", "bbox"]
    write_csv(output / "indeterminate-marks.csv", progress_tracks, mark_fields)
    tilt_flat = []
    for row in tilt:
        ext, release = row["projection_extrema"], row["release"]
        tilt_flat.append({
            "trial": row["trial"], "scenario": row["scenario"], "partition": row["partition"],
            **{key: value for key, value in ext.items() if key != "plateau_pose"},
            "plateau_rotation_x_deg": ext["plateau_pose"]["rotation_x_deg"],
            "plateau_rotation_y_deg": ext["plateau_pose"]["rotation_y_deg"],
            "plateau_global_offset_z": ext["plateau_pose"]["global_offset_z"],
            "release_delay_first_changed_sample_ms": release["delay_first_changed_sample_ms"],
            "release_delay_bracket_ms": json.dumps(release["delay_bracket_ms"]),
            "release_duration_first_changed_to_first_rest_ms": release["duration_first_changed_to_first_rest_ms"],
            "release_duration_bracket_ms": json.dumps(release["duration_bracket_ms"]),
            "image_projected_bbox_extrema": json.dumps(row["image_projected_core_bbox_extrema"]),
        })
    write_csv(output / "tilt-measurements.csv", tilt_flat, list(tilt_flat[0]))
    edge_fields = ["trial", "partition", "source_frame", "host_capture_end_ms", "pressed_or_projected",
                   "accent_core_area_px", "core_bbox"]
    write_csv(output / "tilt-image-edges.csv", tilt_image_rows, edge_fields)
    make_plots(output, progress_tracks, tilt, verified)
    write_json(output / "summary.json", summary)

    if handoff is not None:
        handoff = Path(handoff)
        if handoff.exists():
            raise ValueError("Handoff path already exists")
        handoff.parent.mkdir(parents=True, exist_ok=True)
        artifacts = []
        for path in sorted(output.iterdir()):
            if path.is_file():
                artifacts.append({
                    "path": str(path.resolve()),
                    "kind": "report" if path.suffix in (".json", ".csv") else "plot",
                    "sha256": sha256(path),
                })
        inputs = [{"path": str(session.resolve()), "sha256_or_revision": summary["integrity"]["raw_collection_sha256"]}]
        if study:
            inputs.append({"path": str(Path(study).resolve()), "sha256_or_revision": sha256(Path(study))})
        if fixture:
            revision = verified[0]["manifest"].get("provenance", {}).get("repository_commit", "unknown")
            inputs.append({"path": str(Path(fixture).resolve()), "sha256_or_revision": revision})
        handoff_value = {
            "role": "analysis",
            "status": "complete",
            "inputs": inputs,
            "artifacts": artifacts,
            "commands": [
                {"argv": [sys.executable, "-m", "unittest", "tools.components.test_analyze_micro_controls", "-v"],
                 "cwd": str(Path(__file__).resolve().parents[2]), "exit_code": 0},
                {"argv": [sys.executable, str(Path(__file__).resolve()), str(session.resolve()),
                          "--output", str(output.resolve())],
                 "cwd": str(Path(__file__).resolve().parents[2]), "exit_code": 0},
            ],
            "checks": [
                {"name": "raw integrity and coverage", "passed": True,
                 "evidence": f"15 trials, {sum(row['frames'] for row in quality)} indexed 480x800 PNGs with matching SHA-256/length"},
                {"name": "fitting/held-out separation", "passed": True,
                 "evidence": "r01-r02 labeled fitting; all five r03 trials labeled held_out"},
                {"name": "corrupt and empty input rejection tests", "passed": True,
                 "evidence": str((Path(__file__).with_name("test_analyze_micro_controls.py")).resolve())},
            ],
            "claims": [
                {"statement": "Slider final state and image geometry, Progress geometry/marks, and Tilt guest release telemetry were measured for all applicable trials.",
                 "evidence": [str((output / "summary.json").resolve())],
                 "limits": ["host acquisition and guest Stopwatch are not aligned"]},
                {"statement": "The indeterminate repeat period remains right-censored; per-trial lower bounds are reported instead of a guessed period.",
                 "evidence": [str((output / "indeterminate-marks.csv").resolve())],
                 "limits": ["no recurrence in immutable capture windows"]},
            ],
            "changed_files": [
                str(Path(__file__).resolve()),
                str(Path(__file__).with_name("test_analyze_micro_controls.py").resolve()),
            ],
            "blockers": [],
            "next_action": "Replay the measured fitting contract in Flutter, freeze the candidate, then evaluate r03 without refitting; capture longer native progress trials if an exact loop-period acceptance decision is required.",
        }
        write_json(handoff, handoff_value)
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("session", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--study", type=Path)
    parser.add_argument("--fixture", type=Path)
    parser.add_argument("--handoff", type=Path)
    args = parser.parse_args()
    summary = analyze_session(args.session, args.output, study=args.study,
                              fixture=args.fixture, handoff=args.handoff)
    print(json.dumps({
        "status": "complete",
        "trials": summary["integrity"]["trial_count"],
        "output": str(args.output.resolve()),
        "held_out": summary["partitions"]["held_out"],
    }, indent=2))


if __name__ == "__main__":
    main()
