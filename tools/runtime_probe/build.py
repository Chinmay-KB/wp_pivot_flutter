"""Build the opt-in release web runtime probe, with replay and source hashes."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--flutter', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise SystemExit('Use a fresh output directory to retain build provenance.')
    scenarios = ['core-01/header_next_r01', 'core-01/drag_commit_r01',
                 'confirmation-01/flick_next_path_r01', 'header-01/header_drag_next_r01']
    cases = []
    for scenario in scenarios:
        path = ROOT / 'research/pivot' / scenario / 'replay.json'
        cases.append(dict(id=scenario, sha256=sha(path), replay=json.loads(path.read_text())))
    asset = ROOT / 'example/assets/runtime_replays.json'
    asset.parent.mkdir(exist_ok=True)
    asset.write_text(json.dumps(cases, indent=2))
    sources = [p for base in ['lib', 'example/lib', 'tools/runtime_probe']
               for p in (ROOT / base).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    sources += [ROOT / p for p in ['pubspec.yaml', 'pubspec.lock', 'example/pubspec.yaml',
                                 'example/pubspec.lock', 'example/assets/runtime_replays.json']]
    hashes = {p.relative_to(ROOT).as_posix(): sha(p) for p in sources}
    command = [args.flutter, 'build', 'web', '--release', '--target', 'lib/runtime_probe.dart',
               '--base-href', '/runtime/', '--output', str(output)]
    subprocess.run(command, cwd=ROOT / 'example', check=True)
    (output / 'index.html').write_bytes((ROOT / 'tools/runtime_probe/index.html').read_bytes())
    version = subprocess.check_output([args.flutter, '--version', '--machine'], cwd=ROOT, text=True)
    manifest = dict(command=command, flutter=json.loads(version), source_sha256=hashes,
                    output_sha256={p.relative_to(output).as_posix(): sha(p)
                                   for p in output.rglob('*') if p.is_file()})
    (output / 'build-manifest.json').write_text(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
