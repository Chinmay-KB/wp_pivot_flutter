"""Prepare immutable native pointer replays for WpSplitSurfaceView studies."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare_trial(trial: Path, output: Path, settle_ms: float = 1400) -> Path:
    if output.exists():
        raise FileExistsError(f"fresh output required: {output}")
    manifest_path = trial / "manifest.json"
    events_path = trial / "events.jsonl"
    frames_path = trial / "frames.csv"
    for path in (manifest_path, events_path, frames_path):
        if not path.is_file():
            raise FileNotFoundError(path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("resolution") != [480, 800]:
        raise ValueError(f"unsupported viewport in {manifest_path}")
    if manifest.get("errors"):
        raise ValueError(f"native trial reports capture errors: {trial}")
    pointer = []
    for line in events_path.read_text(encoding="utf-8").splitlines():
        event = json.loads(line)
        if event.get("event") == "pointer":
            pointer.append(event)
    if not pointer or pointer[0].get("phase") != "down" or pointer[-1].get("phase") != "up":
        raise ValueError(f"incomplete pointer stream: {trial}")
    first_down = float(pointer[0]["host_received_ms"])
    events = [
        {
            "t_ms": 500.0 + float(event["host_received_ms"]) - first_down,
            "event": event["phase"],
            "x": float(event["x"]),
            "y": float(event["y"]),
        }
        for event in pointer
    ]
    scenario = str(manifest["scenario"]["id"])
    initial_surface = 1 if scenario.startswith("app_list_to_start") else 0
    commits = "commit" in scenario or "flick" in scenario
    expected_surface = 1 - initial_surface if commits else initial_surface
    replay = {
        "schema_version": 1,
        "adapter_id": "wp81-wvga-split-surface-pointer-v1",
        "source_trial": trial.name,
        "source_trial_path": trial.as_posix(),
        "source_manifest_sha256": _sha256(manifest_path),
        "source_events_sha256": _sha256(events_path),
        "source_frames_sha256": _sha256(frames_path),
        "viewport": [480, 800],
        "timestamp_semantics": (
            "Native host-received pointer times rebased so the first down is "
            "500ms; no events were interpolated or retimed."
        ),
        "initial_surface": initial_surface,
        "expected_surface": expected_surface,
        "events": events,
        "end_ms": events[-1]["t_ms"] + settle_ms,
    }
    output.mkdir(parents=True)
    replay_path = output / "replay.json"
    replay_path.write_text(json.dumps(replay, indent=2), encoding="utf-8")
    return replay_path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("trials", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--settle-ms", type=float, default=1400)
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError(f"fresh output required: {args.output}")
    generated = []
    for trial in args.trials:
        generated.append(
            str(prepare_trial(trial, args.output / trial.name, args.settle_ms))
        )
    print(json.dumps({"generated": generated}, indent=2))


if __name__ == "__main__":
    main()
