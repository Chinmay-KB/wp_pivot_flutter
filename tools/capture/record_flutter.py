"""Render baseline artifacts from recorded native input, with source provenance."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('analysis',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--flutter',type=Path,required=True)
    parser.add_argument('--font-directory',type=Path,default=Path('C:/Windows/Fonts'))
    parser.add_argument('--only',nargs='*')
    parser.add_argument('--variant',choices=['baseline','improved'],default='baseline')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[2]
    fonts=[args.font_directory/n for n in ('segoeui.ttf','segoeuil.ttf','segoeuib.ttf')]
    revision=subprocess.run(['git','rev-parse','HEAD'],cwd=root,capture_output=True,text=True,check=True).stdout.strip()
    version=subprocess.run([str(args.flutter),'--version','--machine'],cwd=root,capture_output=True,text=True,check=True)
    for replay in sorted(args.analysis.glob('*/replay.json')):
        if args.only and replay.parent.name not in args.only:continue
        hashes={str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
                for base in (root/'lib',root/'tools/flutter_capture') for p in base.rglob('*.dart')}
        hashes['pubspec.yaml']=hashlib.sha256((root/'pubspec.yaml').read_bytes()).hexdigest()
        output=(args.output/replay.parent.name).resolve()
        command=[str(args.flutter),'test','tools/flutter_capture/capture_test.dart',
                 '--dart-define=VARIANT='+args.variant,
                 '--dart-define=REPLAY='+replay.resolve().as_posix(),
                 '--dart-define=OUTPUT='+output.as_posix()]
        command += ['--dart-define=FONT_'+name+'='+font.resolve().as_posix()
                    for name,font in zip(('REGULAR','LIGHT','BOLD'),fonts)]
        if args.variant=='improved':
            used_fonts=[root/'assets/fonts'/name for name in ('selawksl.ttf','selawk.ttf','selawksb.ttf')]
        else: used_fonts=fonts
        subprocess.run(command,cwd=root,check=True)
        manifest=json.loads((output/'manifest.json').read_text())
        manifest.update(repository_commit=revision,source_sha256=hashes,
                        font_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in used_fonts},
                        flutter_version=json.loads(version.stdout),
                        replay_sha256=hashlib.sha256(replay.read_bytes()).hexdigest())
        (output/'manifest.json').write_text(json.dumps(manifest,indent=2))


if __name__=='__main__':main()
