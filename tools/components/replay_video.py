"""Encode deterministic Flutter replay PNGs at their declared test-clock cadence.

This is a test-clock visualization, not a live capture or aligned comparison.
"""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import subprocess

import imageio_ffmpeg
from PIL import Image


def encode(trial, output):
    trial, output = Path(trial), Path(output)
    if output.exists():
        raise ValueError('Choose a fresh media output.')
    manifest = json.loads((trial / 'manifest.json').read_text())
    with (trial / 'frames.csv').open(newline='') as file:
        rows = list(csv.DictReader(file))
    if not rows or len(rows) > 3601 or len(rows) != manifest['frame_count']:
        raise ValueError('Empty or incomplete replay.')
    expected = {f'{i:06d}.png' for i in range(len(rows))}
    if {p.name for p in (trial / 'frames').glob('*.png')} != expected:
        raise ValueError('Unexpected replay frame membership.')
    inventory = []
    for i, row in enumerate(rows):
        timestamp = float(row['t_ms'])
        if int(row['frame']) != i or not math.isfinite(timestamp) or abs(timestamp - i * 33.333) > .001:
            raise ValueError('Unexpected test-clock cadence.')
        path = trial / 'frames' / f'{i:06d}.png'
        with Image.open(path) as image:
            if list(image.size) != manifest['resolution']:
                raise ValueError('Unexpected frame dimensions.')
        inventory.append({'frame': i, 't_ms': row['t_ms'],
                          'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    output.mkdir(parents=True)
    video = output / 'flutter.mp4'
    writer = imageio_ffmpeg.write_frames(str(video), tuple(manifest['resolution']),
                                        fps=1000000 / 33333, codec='libx264',
                                        pix_fmt_in='rgb24', pix_fmt_out='yuv420p',
                                        macro_block_size=1, output_params=['-movflags', '+faststart'])
    writer.send(None)
    try:
        for i in range(len(rows)):
            with Image.open(trial / 'frames' / f'{i:06d}.png') as image:
                writer.send(image.convert('RGB').tobytes())
    finally:
        writer.close()
    result = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error', '-i',
                             str(video), '-f', 'null', '-'], capture_output=True, text=True)
    if result.returncode or result.stderr:
        raise RuntimeError('Full video decode failed: ' + result.stderr)
    report = {'source': str(trial.resolve()), 'frames': inventory,
              'video_sha256': hashlib.sha256(video.read_bytes()).hexdigest(),
              'fully_decoded': True, 'fidelity_verified': False,
              'timing': 'Deterministic 33.333ms test-clock frames. Not live performance or guest-clock alignment.'}
    (output / 'summary.json').write_text(json.dumps(report, indent=2))
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('trial', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    report = encode(args.trial, args.output)
    print(f"Encoded and decoded {len(report['frames'])} replay frames.")
