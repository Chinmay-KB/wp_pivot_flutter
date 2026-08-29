"""Immutable supplement to the original Pivot evidence release."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path
from bundle_evidence import archive, sha256


def files_under(paths):
    return [(p, p.as_posix()) for path in paths for p in Path(path).rglob('*')
            if p.is_file() and '__pycache__' not in p.parts]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    assets = []
    groups = {
        'pivot-header': ['artifacts/native-header-01', 'artifacts/flutter-header-01',
                         'artifacts/comparisons-header-01', 'research/pivot/header-01',
                         'research/pivot/comparisons/header-01'],
        'pivot-runtime': ['artifacts/runtime-01', 'artifacts/runtime-web-01',
                          'research/pivot/runtime-01'],
    }
    for name, paths in groups.items():
        assets.append(archive(args.output/(name+'.zip'), files_under(paths)))
    tracked = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], text=True).split('\0')
    source = [(Path(p), 'wp_pivot_flutter/'+p) for p in tracked if p and Path(p).is_file()
              and (Path(p).parts[0] in {'lib', 'tools', 'example', 'assets', 'test'}
                   or p in ['pubspec.yaml', 'pubspec.lock', 'README.md', '.gitattributes', 'analysis_options.yaml'])]
    assets.append(archive(args.output/'pivot-source.zip', source))
    for scenario in ['header_drag_next', 'header_drag_previous']:
        for filename, suffix in [('comparison.mp4', ''), ('comparison-annotated.mp4', '-pointers')]:
            target = args.output/f'{scenario}{suffix}.mp4'
            shutil.copyfile(Path('artifacts/comparisons-header-01')/scenario/filename, target)
            assets.append(dict(file=target.name, bytes=target.stat().st_size, sha256=sha256(target)))
    for name in ['header-regression.log', 'header-flutter-analyze.log', 'header-final-checks.log']:
        path = Path('artifacts')/name
        if path.exists():
            shutil.copyfile(path, args.output/name)
            assets.append(dict(file=name, bytes=path.stat().st_size, sha256=sha256(path)))
    result = dict(schema_version=1, assets=assets,
        supplements='pivot-evidence-2026-08-27; original archives remain unchanged',
        contents='Nine native gesture trials (including timing-unqualified title trials), '
          'two Flutter image captures, comparisons, real release-web runtime report, '
          'compiled probe, exact probe build sources, analyses and current source.',
        source_note='The runtime build-source directory matches its build-manifest hashes. '
          'Current runtime entrypoint removes one unused import. The Glance bridge '
          'is unchanged from the original evidence release and remains available there.',
        fonts='Only OFL Selawik fonts; no installed Windows fonts are redistributed.')
    (args.output/'release-manifest.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
