"""Capture Windows Phone 8.1 shell scenarios without app-specific assumptions.

This is a thin adapter over tools/capture/record_native.py's immutable frame and
event writer.  It intentionally does not launch, deploy, identify, or export an
application.  Each trial is reset with the Home key and retains the reset frame
that was visually checked before coordinate-bearing scenarios were enabled.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


ADAPTER_ID = "start-screen-wp81-wvga"
VIEWPORT = [480, 800]
ALLOWED_KEYS = {"home", "back"}
ALLOWED_OPS = {"wait", "key", "tap", "swipe", "hold"}
INITIAL_STATES = {"start-rest", "app-list-rest", "alphabet-grid-rest", "safe-app"}


class PlanError(ValueError):
    """Raised when an OS-shell scenario plan is unsafe or ambiguous."""


def _number(value: Any, name: str, *, minimum: float, maximum: float) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise PlanError(f"{name} must be numeric")
    value = float(value)
    if not minimum <= value <= maximum:
        raise PlanError(f"{name} must be between {minimum} and {maximum}")
    return value


def _point(action: dict[str, Any], x_name: str, y_name: str) -> None:
    x, y = action.get(x_name), action.get(y_name)
    if isinstance(x, bool) or isinstance(y, bool) or not isinstance(x, int) or not isinstance(y, int):
        raise PlanError(f"{x_name}/{y_name} must be integer screenshot pixels")
    if not (0 <= x < VIEWPORT[0] and 0 <= y < VIEWPORT[1]):
        raise PlanError(f"{x_name}/{y_name} must be inside the 480x800 guest viewport")


def _validate_actions(scenario_id: str, actions: Any, *, field: str) -> bool:
    """Validate image-coordinate actions and return whether any use coordinates."""
    if not isinstance(actions, list):
        raise PlanError(f"{scenario_id}: {field} must be a list")
    coordinate_bearing = False
    for action in actions:
        if not isinstance(action, dict) or action.get("op") not in ALLOWED_OPS:
            raise PlanError(f"{scenario_id}: unsupported {field} action")
        op = action["op"]
        if op == "wait":
            _number(action.get("seconds"), f"{field} wait seconds", minimum=0, maximum=10)
        elif op == "key":
            if action.get("name") not in ALLOWED_KEYS:
                raise PlanError(f"{scenario_id}: only Home and Back keys are allowed")
        elif op == "tap":
            _point(action, "x", "y")
            coordinate_bearing = True
        elif op == "hold":
            _point(action, "x", "y")
            _number(action.get("ms"), f"{field} hold ms", minimum=50, maximum=3000)
            coordinate_bearing = True
        elif op == "swipe":
            _point(action, "x", "y")
            _point(action, "x1", "y1")
            _number(action.get("ms"), f"{field} swipe ms", minimum=50, maximum=3000)
            coordinate_bearing = True
    return coordinate_bearing


def validate_plan(plan: Any, only: list[str] | None = None) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    if not isinstance(plan, dict) or plan.get("schema_version") != 1:
        raise PlanError("plan must be a schema_version 1 object")
    if plan.get("adapter_id") != ADAPTER_ID:
        raise PlanError(f"adapter_id must be {ADAPTER_ID}")
    if plan.get("reference_viewport") != VIEWPORT:
        raise PlanError("reference_viewport must be [480, 800]")
    _number(plan.get("reset_settle_seconds"), "reset_settle_seconds", minimum=0.5, maximum=10)
    _number(plan.get("pre_roll_seconds"), "pre_roll_seconds", minimum=0, maximum=10)
    _number(plan.get("post_roll_seconds"), "post_roll_seconds", minimum=0, maximum=10)

    scenarios = plan.get("scenarios")
    if not isinstance(scenarios, list) or not scenarios:
        raise PlanError("scenarios must be a non-empty list")
    ids: set[str] = set()
    for scenario in scenarios:
        if not isinstance(scenario, dict):
            raise PlanError("each scenario must be an object")
        scenario_id = scenario.get("id")
        if not isinstance(scenario_id, str) or not scenario_id or scenario_id in ids:
            raise PlanError("scenario ids must be unique non-empty strings")
        ids.add(scenario_id)
        if scenario.get("initial_state") not in INITIAL_STATES:
            raise PlanError(f"{scenario_id}: initial_state must be one of {sorted(INITIAL_STATES)}")
        if scenario.get("requires_visual_coordinate_check") not in (None, True, False):
            raise PlanError(f"{scenario_id}: requires_visual_coordinate_check must be boolean")
        if scenario.get("coordinate_verified") not in (None, True, False):
            raise PlanError(f"{scenario_id}: coordinate_verified must be boolean")
        actions = scenario.get("actions")
        precondition_actions = scenario.get("precondition_actions", [])
        coordinate_bearing = _validate_actions(scenario_id, actions, field="actions")
        coordinate_bearing |= _validate_actions(
            scenario_id, precondition_actions, field="precondition_actions"
        )
        if coordinate_bearing:
            if scenario.get("requires_visual_coordinate_check") is not True:
                raise PlanError(f"{scenario_id}: coordinate actions must require visual verification")
            if not isinstance(scenario.get("coordinate_evidence"), str) or not scenario["coordinate_evidence"].strip():
                raise PlanError(f"{scenario_id}: coordinate actions need coordinate_evidence")

    requested = set(only or ids)
    unknown = requested - ids
    if unknown:
        raise PlanError("unknown scenario ids: " + ", ".join(sorted(unknown)))
    selected = [scenario for scenario in scenarios if scenario["id"] in requested]
    if not selected:
        raise PlanError("scenario selection is empty")
    unsafe = [
        scenario["id"] for scenario in selected
        if scenario.get("requires_visual_coordinate_check")
        and not scenario.get("coordinate_verified", False)
    ]
    if unsafe:
        raise PlanError(
            "coordinate-bearing scenarios need visual verification before capture: "
            + ", ".join(unsafe)
        )
    return plan, selected


def prepare_output(output: Path) -> None:
    """Create a fresh session root before any live-device call."""
    output.mkdir(parents=True, exist_ok=False)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_hashes(root: Path) -> dict[str, str]:
    return {
        str(path.relative_to(root)).replace("\\", "/"): sha256(path)
        for path in sorted(root.rglob("*"))
        if path.is_file() and path.suffix.lower() in {".py", ".ps1"}
        and "__pycache__" not in path.parts
    }


def save_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2), encoding="utf-8")


def _git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=repo, capture_output=True, text=True, check=True
    ).stdout.strip()


def build_provenance(repo: Path, glance_app: Path, plan_path: Path, label: str) -> dict[str, Any]:
    mirror_repo = glance_app.parent
    recorder = repo / "tools" / "capture" / "record_native.py"
    adapter = Path(__file__).resolve()
    return {
        "label": label,
        "adapter_id": ADAPTER_ID,
        "repository_commit": _git(repo, "rev-parse", "HEAD"),
        "wp_mirror_base_commit": _git(mirror_repo, "rev-parse", "HEAD"),
        "wp_mirror_worktree_status": _git(mirror_repo, "status", "--short", "--untracked-files=all"),
        "wp_mirror_source_sha256": source_hashes(glance_app / "wpmirror"),
        "scenario_plan_sha256": sha256(plan_path),
        "shell_adapter_sha256": sha256(adapter),
        "shared_frame_recorder_sha256": sha256(recorder),
        "source_identity_note": (
            "The wp-mirror base revision plus per-file source hashes identify the dirty source bytes "
            "used by this run; the base revision alone does not."
        ),
    }


def acquire_reset_frame(capture: Any) -> tuple[bytes, dict[str, Any]]:
    started = time.perf_counter_ns()
    result = capture.call("capture", file=True)
    data = Path(result["path"]).read_bytes()
    ended = time.perf_counter_ns()
    from PIL import Image
    import io

    with Image.open(io.BytesIO(data)) as image:
        size = list(image.size)
    if size != VIEWPORT:
        raise RuntimeError(f"Unexpected reset frame size {size}; expected {VIEWPORT}")
    return data, {
        "path": "reset.png",
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "resolution": size,
        "host_capture_interval_ms": (ended - started) / 1e6,
        "visual_verification": "required before coordinate-bearing trial acceptance",
    }


def deliver_action(control: Any, action: dict[str, Any]) -> dict[str, Any]:
    """Deliver one allowlisted precondition action with its explicit receipt."""
    if action["op"] == "wait":
        time.sleep(action["seconds"])
        return {"op": "wait", "result": "elapsed"}
    delivered = action
    if action["op"] == "hold":
        delivered = {"op": "swipe", "x": action["x"], "y": action["y"],
                     "x1": action["x"], "y1": action["y"], "ms": action["ms"]}
    return {"op": action["op"], "delivered": delivered, "result": control.call(**delivered)}


def run(args: argparse.Namespace) -> None:
    plan_path = args.plan.resolve()
    plan, selected = validate_plan(json.loads(plan_path.read_text(encoding="utf-8")), args.only)
    output = args.output.resolve()
    prepare_output(output)
    save_json(output / "plan.json", plan)

    repo = Path(__file__).resolve().parents[2]
    provenance = build_provenance(repo, args.glance_app.resolve(), plan_path, args.label)
    save_json(output / "provenance.json", provenance)

    sys.path.insert(0, str((repo / "tools" / "capture").resolve()))
    sys.path.insert(0, str(args.glance_app.resolve()))
    from record_native import record_trial
    from wpmirror.emulator import XdeBridge

    session_errors: list[str] = []
    capture = control = None
    try:
        capture, control = XdeBridge(), XdeBridge()
        status = capture.call("status")
        if not status.get("ready"):
            raise RuntimeError(f"Emulator shell is not ready: {status}")
        control.call("status")
        for scenario in selected:
            for repeat in range(args.repetitions):
                trial = output / f"{scenario['id']}_r{repeat + 1:02d}"
                control.call("key", name="home")
                time.sleep(plan["reset_settle_seconds"])
                precondition_bytes, precondition = acquire_reset_frame(capture)
                precondition_events = []
                for action in scenario.get("precondition_actions", []):
                    requested_at = time.perf_counter_ns()
                    receipt = deliver_action(control, action)
                    precondition_events.append({
                        "requested_action": action,
                        "host_request_monotonic_ns": requested_at,
                        "receipt": receipt,
                        "clock_semantics": "Host request/SDK receipt, not guest presentation or touch time.",
                    })
                if scenario.get("precondition_actions"):
                    time.sleep(plan["reset_settle_seconds"])
                reset_bytes, reset = acquire_reset_frame(capture)
                manifest = record_trial(
                    capture,
                    control,
                    scenario,
                    trial,
                    plan["pre_roll_seconds"],
                    plan["post_roll_seconds"],
                    status,
                    provenance,
                    control_name="Windows Phone 8.1 Start screen OS shell",
                )
                (trial / "precondition.png").write_bytes(precondition_bytes)
                save_json(trial / "precondition-events.json", precondition_events)
                manifest["precondition"] = {
                    "declared_initial_state": scenario["initial_state"],
                    "frame": {**precondition, "path": "precondition.png"},
                    "actions": scenario.get("precondition_actions", []),
                    "events": "precondition-events.json",
                    "semantics": "Frame before coordinate-bearing precondition actions; visually inspect before accepting input coordinates.",
                }
                (trial / "reset.png").write_bytes(reset_bytes)
                manifest["reset"] = {
                    "operation": {"op": "key", "name": "home"},
                    "settle_seconds": plan["reset_settle_seconds"],
                    "frame": reset,
                    "semantics": "The retained frame was acquired after declared preconditions and immediately before trial capture; it is the exact clean frame for action-coordinate verification.",
                }
                save_json(trial / "manifest.json", manifest)
                control.call("key", name="home")
                time.sleep(plan["reset_settle_seconds"])
    except Exception as exc:
        session_errors.append(str(exc))
        raise
    finally:
        if capture is not None:
            capture.close()
        if control is not None:
            control.close()
        save_json(
            output / "session.json",
            {
                "schema_version": 1,
                "adapter_id": ADAPTER_ID,
                "selected_scenarios": [s["id"] for s in selected],
                "repetitions": args.repetitions,
                "errors": session_errors,
                "outcome": "failed" if session_errors else "captured-not-yet-visually-qualified",
            },
        )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--glance-app", type=Path, required=True)
    parser.add_argument("--plan", type=Path, default=Path(__file__).with_name("scenarios.json"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, default=1)
    parser.add_argument("--only", nargs="*")
    parser.add_argument("--label", default="exploratory-pilot")
    args = parser.parse_args(argv)
    if args.repetitions < 1 or args.repetitions > 10:
        parser.error("--repetitions must be 1..10")
    return args


def main(argv: list[str] | None = None) -> None:
    run(parse_args(argv))


if __name__ == "__main__":
    main()
