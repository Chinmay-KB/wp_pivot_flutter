"""Compare a fresh batch of lateral Flutter runs with their native sources."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from compare_lateral import compare


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("flutter_roots", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError(f"fresh output required: {args.output}")
    args.output.mkdir(parents=True)
    runs = []
    for root in args.flutter_roots:
        runs.extend(path.parent for path in sorted(root.glob("*/replay.json")))
    if args.only:
        runs = [run for run in runs if run.name in args.only]
    if not runs:
        raise FileNotFoundError("no matching Flutter replay runs")
    reports = []
    failures = []
    for run in runs:
        replay = json.loads((run / "replay.json").read_text(encoding="utf-8"))
        native = Path(replay["source_trial_path"])
        try:
            report = compare(native, run, args.output / run.name)
            reports.append(report)
        except Exception as error:  # Preserve every per-trial report before failing.
            failures.append({"trial": run.name, "error": str(error)})
    summary = {
        "schema_version": 1,
        "adapter_id": "wp81-wvga-split-surface-trajectory-batch-v1",
        "trials": [
            {
                "trial": Path(report["native_trial"]).name,
                "passed": report["passed"],
                "registered_lag_ms": report["presentation_registered_alignment"][
                    "lag_ms"
                ],
                "registered_tracking_p95_px": report[
                    "presentation_registered_alignment"
                ]["tracking"]["p95_abs_error_px"],
                "direct_tracking_p95_px": report[
                    "direct_host_timestamp_alignment"
                ]["tracking"]["p95_abs_error_px"],
                "final_error_px": report["final"]["abs_error_px"],
                "surface_separation_error_px": report["surface_separation"][
                    "max_abs_error_px"
                ],
            }
            for report in reports
        ],
        "failures": failures,
        "passed": not failures and all(report["passed"] for report in reports),
    }
    (args.output / "summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))
    if not summary["passed"]:
        raise ValueError(f"lateral batch failed: {failures}")


if __name__ == "__main__":
    main()
