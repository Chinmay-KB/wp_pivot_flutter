"""Run deterministic WpSplitSurfaceView replays with source provenance."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("replays", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--flutter", type=Path, required=True)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    if args.output.exists():
        raise FileExistsError(f"fresh output required: {args.output}")
    revision = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    version = subprocess.run(
        [str(args.flutter), "--version", "--machine"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    )
    replay_paths = sorted(args.replays.glob("*/replay.json"))
    if not replay_paths:
        raise FileNotFoundError(f"no replays under {args.replays}")
    for replay in replay_paths:
        if args.only and replay.parent.name not in args.only:
            continue
        output = (args.output / replay.parent.name).resolve()
        command = [
            str(args.flutter),
            "test",
            "tools/launcher/lateral_capture_test.dart",
            f"--dart-define=REPLAY={replay.resolve().as_posix()}",
            f"--dart-define=OUTPUT={output.as_posix()}",
        ]
        subprocess.run(command, cwd=root, check=True)
        source_files = [
            *sorted((root / "lib").rglob("*.dart")),
            root / "tools/launcher/lateral_capture_test.dart",
            root / "tools/launcher/record_flutter_lateral.py",
            root / "pubspec.yaml",
            root / "pubspec.lock",
        ]
        manifest_path = output / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest.update(
            repository_commit=revision,
            source_sha256={
                path.relative_to(root).as_posix(): _sha256(path)
                for path in source_files
            },
            flutter_version=json.loads(version.stdout),
            replay_sha256=_sha256(replay),
        )
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
