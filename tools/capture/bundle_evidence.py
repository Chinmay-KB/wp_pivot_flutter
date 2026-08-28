"""Package all retained Pivot evidence, including unsuccessful/prototype trials.

Only local files are written. Upload/publication is a separate explicit step.
No installed Windows fonts are included. Every member has a SHA-256 inventory.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile
from pathlib import Path


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def archive(output, files):
    files=sorted(files,key=lambda item:item[1])
    inventory=[]
    with zipfile.ZipFile(output,'x',zipfile.ZIP_DEFLATED,compresslevel=1) as target:
        for path,name in files:
            raw=path.read_bytes()
            target.writestr(name,raw)
            inventory.append(dict(path=name,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
        target.writestr('INVENTORY.json',json.dumps(inventory,indent=2))
    # Independently reopen and verify every archived member against the inventory.
    with zipfile.ZipFile(output) as source:
        for entry in inventory:
            raw=source.read(entry['path'])
            if hashlib.sha256(raw).hexdigest()!=entry['sha256']:
                raise RuntimeError('Archive verification failed: '+entry['path'])
    return dict(file=output.name,bytes=output.stat().st_size,sha256=sha256(output),members=len(inventory))


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--glance-app',type=Path,required=True)
    parser.add_argument('--final-comparisons',type=Path,required=True)
    args=parser.parse_args()
    if args.output.exists():raise SystemExit('Use a new immutable bundle directory.')
    args.output.mkdir(parents=True)
    assets=[]
    for name,pattern in [('native','native-*'),('flutter','flutter-*'),('comparisons','comparisons-*')]:
        files=[(p,p.as_posix()) for folder in Path('artifacts').glob(pattern)
               if folder.is_dir() for p in folder.rglob('*') if p.is_file()]
        assets.append(archive(args.output/f'pivot-{name}.zip',files))
    files=[(p,p.as_posix()) for p in Path('research/pivot').rglob('*') if p.is_file()]
    assets.append(archive(args.output/'pivot-analysis.zip',files))
    source_paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],text=True).split('\0')
    allowed={'lib','tools','assets','example','test'}
    files=[(Path(p),'wp_pivot_flutter/'+p) for p in source_paths if p and Path(p).is_file()
           and (Path(p).parts[0] in allowed or p in ['pubspec.yaml','pubspec.lock','README.md','CHANGELOG.md','.gitattributes'])]
    files += [(p,'glance/app/'+p.relative_to(args.glance_app).as_posix())
              for p in (args.glance_app/'wpmirror').rglob('*')
              if p.is_file() and p.suffix in ['.py','.ps1']]
    files += [(args.glance_app/name,'glance/app/'+name) for name in ['pyproject.toml','wp_mirror.py']]
    assets.append(archive(args.output/'pivot-source.zip',files))
    for directory in sorted(args.final_comparisons.iterdir()):
        if not directory.is_dir():continue
        for file,suffix in [('comparison.mp4',''),('comparison-annotated.mp4','-pointers')]:
            source=directory/file
            if source.exists():
                target=args.output/f'{directory.name}{suffix}.mp4'
                shutil.copyfile(source,target)
                assets.append(dict(file=target.name,bytes=target.stat().st_size,sha256=sha256(target)))
    result=dict(schema_version=1,assets=assets,
        source_note='Source snapshot is the actual working files, not merely the last commit. Source archive includes the Glance bridge needed to reproduce timed gesture paths.',
        retention='All local native, Flutter and comparison collections are retained, including baseline/prototype/failed-outcome trials. See their individual manifests for source, validity and limitations.',
        fonts='Only the bundled OFL Selawik source assets are distributed. Installed Segoe font files are not included.')
    (args.output/'release-manifest.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
