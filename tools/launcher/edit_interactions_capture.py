"""Immutable WP8.1 Start-screen edit-interaction recorder.

This is deliberately a shell-specific adapter.  It owns one capture and one
input bridge within the caller's fidelity emulator lease and records only host
clock observations; it does not reuse the Pivot tracker or infer guest timing.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import sys
import time
from pathlib import Path

from PIL import Image

VIEWPORT = [480, 800]
ADAPTER = "start-screen-wp81-wvga-edit-interactions-v1"


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _save(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2), encoding="utf-8")


def _frame(capture: object) -> tuple[bytes, dict[str, object]]:
    started = time.perf_counter_ns()
    result = capture.call("capture", file=True)
    data = Path(result["path"]).read_bytes()
    ended = time.perf_counter_ns()
    with Image.open(io.BytesIO(data)) as image:
        if list(image.size) != VIEWPORT:
            raise RuntimeError(f"unexpected emulator frame {image.size}")
    return data, {
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "resolution": VIEWPORT,
        "host_capture_interval_ms": (ended - started) / 1e6,
        "clock_semantics": "Host acquisition interval, not guest presentation time.",
    }


def _deliver(control: object, action: dict[str, object]) -> dict[str, object]:
    if action["op"] == "wait":
        time.sleep(float(action["seconds"]))
        return {"op": "wait", "result": "elapsed"}
    if action["op"] == "hold":
        action = {"op": "swipe", "x": action["x"], "y": action["y"],
                  "x1": action["x"], "y1": action["y"], "ms": action["ms"]}
    return {"op": action["op"], "delivered": action, "result": control.call(**action)}


def _validate(plan: dict[str, object], only: set[str] | None) -> list[dict[str, object]]:
    if plan.get("schema_version") != 1 or plan.get("adapter_id") != ADAPTER:
        raise ValueError("unexpected edit-interaction plan")
    if plan.get("reference_viewport") != VIEWPORT:
        raise ValueError("plan must target 480x800")
    scenarios = plan.get("scenarios")
    if not isinstance(scenarios, list):
        raise ValueError("scenarios must be a list")
    selected = [item for item in scenarios if not only or item["id"] in only]
    if not selected or any(not item.get("coordinate_verified") for item in selected):
        raise ValueError("selected scenarios require fresh verified coordinates")
    return selected


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--glance-app", type=Path, required=True)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--only", nargs="*")
    parser.add_argument("--trial-label")
    args = parser.parse_args()
    if args.output.exists() or not 1 <= args.repetitions <= 3:
        raise SystemExit("output must be new and repetitions must be 1..3")
    if args.trial_label and args.repetitions != 1:
        raise SystemExit("--trial-label requires one repetition")
    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    scenarios = _validate(plan, set(args.only or []))
    args.output.mkdir(parents=True)
    _save(args.output / "plan.json", plan)
    repo = Path(__file__).resolve().parents[2]
    sys.path[:0] = [str(args.glance_app), str(repo / "tools" / "capture")]
    from record_native import record_trial
    from wpmirror.emulator import XdeBridge

    provenance = {
        "adapter_id": ADAPTER,
        "adapter_sha256": _sha(Path(__file__).resolve()),
        "plan_sha256": _sha(args.plan),
        "calibration": plan["calibration"],
        "source": "Windows Phone 8.1 emulator Start shell",
    }
    errors: list[str] = []
    capture = control = None
    try:
        capture, control = XdeBridge(), XdeBridge()
        status = capture.call("status")
        if not status.get("ready"):
            raise RuntimeError(f"emulator not ready: {status}")
        for scenario in scenarios:
            for number in range(1, args.repetitions + 1):
                control.call("key", name="home")
                time.sleep(float(plan["reset_settle_seconds"]))
                before, before_meta = _frame(capture)
                pre_events = []
                for action in scenario.get("precondition_actions", []):
                    requested = time.perf_counter_ns()
                    pre_events.append({"requested_action": action,
                                       "host_request_monotonic_ns": requested,
                                       "receipt": _deliver(control, action),
                                       "clock_semantics": "Host request/receipt, not guest touch time."})
                if scenario.get("precondition_actions"):
                    time.sleep(float(plan["precondition_settle_seconds"]))
                reset, reset_meta = _frame(capture)
                suffix = args.trial_label or f"r{number:02d}"
                trial = args.output / f"{scenario['id']}_{suffix}"
                manifest = record_trial(capture, control, scenario, trial,
                                        float(plan["pre_roll_seconds"]),
                                        float(plan["post_roll_seconds"]), status,
                                        provenance,
                                        control_name="Windows Phone 8.1 Start shell edit interaction")
                (trial / "precondition.png").write_bytes(before)
                (trial / "reset.png").write_bytes(reset)
                _save(trial / "precondition-events.json", pre_events)
                manifest["precondition"] = {"frame": {**before_meta, "path": "precondition.png"},
                                            "events": "precondition-events.json"}
                manifest["reset"] = {"frame": {**reset_meta, "path": "reset.png"},
                                     "return_path": "Home key after each trial"}
                _save(trial / "manifest.json", manifest)
                control.call("key", name="home")
                time.sleep(float(plan["reset_settle_seconds"]))
    except Exception as error:
        errors.append(str(error))
        raise
    finally:
        if capture is not None: capture.close()
        if control is not None: control.close()
        _save(args.output / "session.json", {"schema_version": 1, "adapter_id": ADAPTER,
                                               "errors": errors,
                                               "outcome": "failed" if errors else "captured-not-yet-qualified"})


if __name__ == "__main__":
    main()
