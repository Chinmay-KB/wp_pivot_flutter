"""Verify native pilot bytes and make a held-frame video plus acquisition report.

Playback uses host capture-end times. No interpolation, clock alignment, fitted
curve, or comparison with Flutter is implied by this derived video.
"""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import statistics

import imageio_ffmpeg
from PIL import Image


def summarize(trial, output, fps=30):
    trial, output = Path(trial), Path(output)
    if type(fps) is not int or not 1 <= fps <= 120:
        raise ValueError('Playback fps must be an integer from 1 to 120.')
    if output.exists():
        raise ValueError('Derived output must be new.')
    manifest = json.loads((trial / 'manifest.json').read_text())
    with (trial / 'frames.csv').open(newline='', encoding='utf-8') as file:
        rows = list(csv.DictReader(file))
    if manifest.get('errors') or not rows or manifest['frame_count'] != len(rows):
        raise ValueError('Failed or empty capture.')
    starts, ends, hashes = [], [], []
    for i, row in enumerate(rows):
        if int(row['frame']) != i:
            raise ValueError('Unexpected frame index.')
        frame = trial / 'frames' / f'{i:06d}.png'
        data = frame.read_bytes()
        if hashlib.sha256(data).hexdigest() != row['sha256'] or len(data) != int(row['bytes']):
            raise ValueError('Raw frame integrity failed.')
        with Image.open(frame) as image:
            if list(image.size) != manifest['resolution']:
                raise ValueError('Frame dimensions changed.')
        start, end = float(row['capture_start_ms']), float(row['capture_end_ms'])
        if not math.isfinite(start) or not math.isfinite(end) or start < 0 or end <= start or ends and start < ends[-1]:
            raise ValueError('Invalid acquisition interval.')
        starts.append(start)
        ends.append(end)
        hashes.append(row['sha256'])
    expected = {f'{i:06d}.png' for i in range(len(rows))}
    if {p.name for p in (trial / 'frames').glob('*.png')} != expected:
        raise ValueError('Unexpected raw frame membership.')
    duration = (ends[-1] - ends[0]) / 1000
    if duration > 120:
        raise ValueError('Pilot exceeds bounded 120-second media limit.')
    output.mkdir(parents=True)
    size = tuple(manifest['resolution'])
    writer = imageio_ffmpeg.write_frames(str(output / 'native.mp4'), size, fps=fps,
                                         codec='libx264', pix_fmt_in='rgb24', pix_fmt_out='yuv420p',
                                         macro_block_size=1, output_params=['-movflags', '+faststart'])
    writer.send(None)
    mapping, current, cached = [], -1, None
    source_index = 0
    try:
        for video_index in range(max(1, math.ceil(duration * fps) + 1)):
            host_ms = ends[0] + video_index * 1000 / fps
            while source_index + 1 < len(rows) and ends[source_index + 1] <= host_ms:
                source_index += 1
            if current != source_index:
                with Image.open(trial / 'frames' / f'{source_index:06d}.png') as image:
                    cached = image.convert('RGB').tobytes()
                current = source_index
            writer.send(cached)
            mapping.append({'video_frame': video_index, 'video_time_ms': video_index * 1000 / fps,
                            'host_capture_timeline_ms': host_ms, 'source_frame': source_index,
                            'source_capture_end_ms': ends[source_index], 'source_sha256': hashes[source_index]})
    finally:
        writer.close()
    with (output / 'video-frame-map.csv').open('w', newline='', encoding='utf-8') as file:
        table = csv.DictWriter(file, fieldnames=list(mapping[0]))
        table.writeheader()
        table.writerows(mapping)
    gaps = [b - a for a, b in zip(starts, starts[1:])]
    report = {
        'source': str(trial.resolve()), 'control': manifest['control'], 'raw_hashes_verified': True,
        'frames': len(rows), 'distinct_frames': len(set(hashes)), 'resolution': size,
        'capture_fps': manifest['capture_fps'], 'median_capture_interval_ms': statistics.median(gaps) if gaps else None,
        'max_capture_interval_ms': max(gaps, default=None), 'encoded_fps': fps, 'encoded_frames': len(mapping),
        'video_sha256': hashlib.sha256((output / 'native.mp4').read_bytes()).hexdigest(),
        'timing': 'Held original frames on host capture-end timeline, origin at first capture end. No motion interpolation.',
        'qualified_for_aligned_motion': False,
        'limits': ['Pilot capture only; guest/Flutter clocks not aligned.',
                   'Encoded frame rate does not increase observed temporal resolution.',
                   'Inspect initial frame and guest state separately; no automatic reset assertion.',
                   'No hardware latency or Flutter runtime performance claim.'],
    }
    (output / 'summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('trial', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(summarize(args.trial, args.output), indent=2))
