"""Measure WpSplitSurfaceView response against native WP8.1 trajectories."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from collections import deque
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

ACCENT = (62, 101, 255)
VIEWPORT_WIDTH = 480.0


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _components(image: Image.Image) -> list[tuple[int, int, int, int, int]]:
    pixels = image.convert("RGB").load()
    width, height = image.size
    remaining = {
        (x, y)
        for y in range(height)
        for x in range(width)
        if pixels[x, y] == ACCENT
    }
    result = []
    while remaining:
        start = remaining.pop()
        queue = deque([start])
        points = [start]
        while queue:
            x, y = queue.popleft()
            for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if point in remaining:
                    remaining.remove(point)
                    queue.append(point)
                    points.append(point)
        if len(points) >= 100:
            xs = [point[0] for point in points]
            ys = [point[1] for point in points]
            result.append((len(points), min(xs), min(ys), max(xs), max(ys)))
    return result


def extract_native_offset(frame: Path) -> tuple[float, dict] | None:
    """Return the page-zero left edge using Start or app-list color anchors."""
    components = _components(Image.open(frame))
    candidates: list[tuple[str, float, tuple[int, int, int, int, int]]] = []
    phone = [
        item
        for item in components
        if item[2] == 56 and item[4] == 265 and item[1] <= 24 and item[3] <= 233
    ]
    if phone:
        item = max(phone)
        candidates.append(("start-phone-right", float(item[3] - 233), item))
    alarm = [
        item
        for item in components
        if item[2] == 131 and item[4] == 192 and 0 <= item[1] <= 479
    ]
    if alarm:
        item = max(alarm)
        candidates.append(("app-alarm-left", float(item[1] - 566), item))
    if not candidates:
        return None
    values = [item[1] for item in candidates]
    if max(values) - min(values) > 1:
        raise ValueError(f"native anchors disagree in {frame}: {candidates}")
    return float(sum(values) / len(values)), {
        "anchors": [
            {"name": name, "offset": value, "component": list(component)}
            for name, value, component in candidates
        ]
    }


def _read_native(trial: Path) -> tuple[np.ndarray, np.ndarray, list[dict], float]:
    pointer = []
    for line in (trial / "events.jsonl").read_text(encoding="utf-8").splitlines():
        event = json.loads(line)
        if event.get("event") == "pointer":
            pointer.append(event)
    first_down = float(pointer[0]["host_received_ms"])
    release = float(pointer[-1]["host_received_ms"]) - first_down
    times = []
    offsets = []
    evidence = []
    with (trial / "frames.csv").open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            frame_number = int(row["frame"])
            frame = trial / "frames" / f"{frame_number:06}.png"
            extracted = extract_native_offset(frame)
            if extracted is None:
                continue
            offset, anchors = extracted
            midpoint = (
                float(row["capture_start_ms"]) + float(row["capture_end_ms"])
            ) / 2
            relative = midpoint - first_down
            times.append(relative)
            offsets.append(offset)
            evidence.append(
                {
                    "frame": frame_number,
                    "relative_ms": relative,
                    "offset": offset,
                    **anchors,
                }
            )
    return np.asarray(times), np.asarray(offsets), evidence, release


def _read_flutter(run: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    times = []
    first = []
    separation = []
    with (run / "frames.csv").open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            times.append(float(row["t_ms"]) - 500.0)
            first.append(float(row["first_left"]))
            separation.append(float(row["second_left"]) - float(row["first_left"]))
    return np.asarray(times), np.asarray(first), np.asarray(separation)


def _metrics(errors: np.ndarray) -> dict:
    absolute = np.abs(errors)
    return {
        "samples": int(len(errors)),
        "mean_abs_error_px": float(np.mean(absolute)),
        "rmse_px": float(math.sqrt(float(np.mean(errors * errors)))),
        "p95_abs_error_px": float(np.percentile(absolute, 95)),
        "max_abs_error_px": float(np.max(absolute)),
    }


def compare(
    native_trial: Path,
    flutter_run: Path,
    output: Path,
    tracking_p95_tolerance_px: float = 36,
    final_tolerance_px: float = 1,
) -> dict:
    if output.exists():
        raise FileExistsError(f"fresh output required: {output}")
    output.mkdir(parents=True)
    replay = json.loads((flutter_run / "replay.json").read_text(encoding="utf-8"))
    manifest = json.loads(
        (flutter_run / "manifest.json").read_text(encoding="utf-8")
    )
    if replay["source_trial"] != native_trial.name:
        raise ValueError("Flutter replay and native trial identities differ")
    native_t, native_x, native_evidence, release = _read_native(native_trial)
    flutter_t, flutter_x, separation = _read_flutter(flutter_run)
    if len(native_t) < 3 or len(flutter_t) < 3:
        raise ValueError("insufficient trajectory samples")
    in_range = (native_t >= flutter_t.min()) & (native_t <= flutter_t.max())
    native_t = native_t[in_range]
    native_x = native_x[in_range]
    native_evidence = [
        item for item, keep in zip(native_evidence, in_range.tolist()) if keep
    ]
    interpolated = np.interp(native_t, flutter_t, flutter_x)
    errors = interpolated - native_x
    tracking = native_t <= release
    settling = native_t > release
    best: tuple[float, float] | None = None
    for lag in np.arange(0.0, 451.0, 1.0):
        registered_mask = (
            tracking
            & (native_t >= flutter_t.min() + lag)
            & (native_t <= flutter_t.max() + lag)
        )
        if int(np.sum(registered_mask)) < 5:
            continue
        registered = np.interp(native_t[registered_mask] - lag, flutter_t, flutter_x)
        registered_errors = registered - native_x[registered_mask]
        rmse = math.sqrt(float(np.mean(registered_errors * registered_errors)))
        if best is None or rmse < best[0]:
            best = (rmse, float(lag))
    if best is None:
        raise ValueError("insufficient samples for presentation registration")
    presentation_lag = best[1]
    registered_mask = (
        (native_t >= flutter_t.min() + presentation_lag)
        & (native_t <= flutter_t.max() + presentation_lag)
    )
    registered = np.interp(
        native_t[registered_mask] - presentation_lag,
        flutter_t,
        flutter_x,
    )
    registered_errors = registered - native_x[registered_mask]
    registered_tracking = tracking[registered_mask]
    registered_settling = settling[registered_mask]
    expected_first = -VIEWPORT_WIDTH * int(replay["expected_surface"])
    final_error = abs(float(flutter_x[-1]) - expected_first)
    outcome_passed = final_error <= final_tolerance_px
    direct_tracking_metrics = _metrics(errors[tracking])
    direct_settling_metrics = _metrics(errors[settling]) if np.any(settling) else None
    tracking_metrics = _metrics(registered_errors[registered_tracking])
    settling_metrics = (
        _metrics(registered_errors[registered_settling])
        if np.any(registered_settling)
        else None
    )
    passed = (
        outcome_passed
        and tracking_metrics["p95_abs_error_px"] <= tracking_p95_tolerance_px
        and float(np.max(np.abs(separation - VIEWPORT_WIDTH))) <= 0.01
    )
    report = {
        "schema_version": 1,
        "adapter_id": "wp81-wvga-split-surface-trajectory-v1",
        "native_source": "Microsoft WP8.1 WVGA emulator",
        "flutter_source": "deterministic Flutter package replay",
        "native_trial": str(native_trial.resolve()),
        "native_manifest_sha256": _sha256(native_trial / "manifest.json"),
        "flutter_run": str(flutter_run.resolve()),
        "flutter_manifest_sha256": _sha256(flutter_run / "manifest.json"),
        "replay_sha256": _sha256(flutter_run / "replay.json"),
        "release_relative_ms": release,
        "measurement": (
            "Page-zero left edge from native flat-color Start/app-list anchors; "
            "Flutter PageController position interpolated only for analysis at "
            "native frame midpoints. Pointer events were not interpolated or retimed."
        ),
        "tracking_tolerance_p95_px": tracking_p95_tolerance_px,
        "tracking_tolerance_basis": (
            "36px bounds the spatial ambiguity of one approximately 90ms "
            "native host-capture interval at the delivered approximately "
            "400px/s drag speed."
        ),
        "final_tolerance_px": final_tolerance_px,
        "direct_host_timestamp_alignment": {
            "tracking": direct_tracking_metrics,
            "settling": direct_settling_metrics,
            "all_samples": _metrics(errors),
            "acceptance_use": False,
            "reason": (
                "Native timestamps bracket host capture and host receipt, not "
                "guest presentation; direct timing is retained as a diagnostic."
            ),
        },
        "presentation_registered_alignment": {
            "lag_ms": presentation_lag,
            "lag_search_range_ms": [0, 450],
            "registration": (
                "Analysis-only constant lag minimizing tracking RMSE; replayed "
                "pointer event timestamps are unchanged."
            ),
            "tracking": tracking_metrics,
            "settling": settling_metrics,
            "all_samples": _metrics(registered_errors),
            "acceptance_use": True,
        },
        "final": {
            "expected_first_left": expected_first,
            "flutter_first_left": float(flutter_x[-1]),
            "abs_error_px": final_error,
            "outcome_passed": outcome_passed,
        },
        "surface_separation": {
            "expected_px": VIEWPORT_WIDTH,
            "max_abs_error_px": float(
                np.max(np.abs(separation - VIEWPORT_WIDTH))
            ),
        },
        "native_samples": native_evidence,
        "sample_comparison": [
            {
                "relative_ms": float(time),
                "native_first_left": float(native),
                "flutter_first_left": float(actual),
                "error_px": float(error),
            }
            for time, native, actual, error in zip(
                native_t, native_x, interpolated, errors
            )
        ],
        "claims": [
            "delivered commit/cancel pointer trajectory response",
            "two surfaces remain one 480px viewport apart",
            "release outcome in deterministic Flutter engine",
        ],
        "limits": [
            "No live Android runtime or physical touch-latency claim.",
            "Native frame times are host capture intervals, not guest presentation timestamps.",
            "Typography and caller-owned icon art are outside this trajectory score.",
        ],
        "passed": passed,
    }
    (output / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    figure, axis = plt.subplots(figsize=(10, 5))
    axis.plot(native_t, native_x, "o-", label="WP8.1 emulator", markersize=3)
    axis.plot(
        flutter_t + presentation_lag,
        flutter_x,
        "-",
        label=f"Flutter package (+{presentation_lag:.0f}ms presentation registration)",
        linewidth=2,
    )
    axis.axvline(release, color="gray", linestyle="--", label="pointer up")
    axis.set_xlabel("milliseconds from first pointer down")
    axis.set_ylabel("first surface left edge (px)")
    axis.set_ylim(-510, 30)
    axis.grid(alpha=0.25)
    axis.legend()
    figure.tight_layout()
    figure.savefig(output / "trajectory.png", dpi=160)
    plt.close(figure)
    if not passed:
        raise ValueError(
            "lateral comparison failed: "
            f"tracking p95={tracking_metrics['p95_abs_error_px']:.2f}px, "
            f"final={final_error:.2f}px"
        )
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--native-trial", type=Path, required=True)
    parser.add_argument("--flutter-run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--tracking-p95-tolerance-px", type=float, default=36)
    parser.add_argument("--final-tolerance-px", type=float, default=1)
    args = parser.parse_args()
    report = compare(
        args.native_trial,
        args.flutter_run,
        args.output,
        args.tracking_p95_tolerance_px,
        args.final_tolerance_px,
    )
    print(json.dumps({"passed": report["passed"], "output": str(args.output)}))


if __name__ == "__main__":
    main()
