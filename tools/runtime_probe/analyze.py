"""Summarize real web engine timings; never infer display fps from test replays."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def distribution(values):
    values = list(values)
    return dict(count=len(values), p50_ms=float(np.median(values)) if values else None,
                p95_ms=float(np.percentile(values, 95)) if values else None,
                max_ms=max(values) if values else None,
                over_60hz_budget=sum(v > 1000 / 60 for v in values))


def animation_gaps(frames, selections, duration_us=750000):
    # Only the continuously animated post-selection phase; idle/drag event gaps
    # must not be mixed into this cadence metric. Do not filter out large gaps.
    gaps = []
    for selection in selections:
        start = selection['absolute_us']
        times = sorted(f['vsyncStart'] for f in frames
                       if start <= f['vsyncStart'] <= start + duration_us)
        gaps.extend((b-a)/1000 for a, b in zip(times, times[1:]))
    return gaps


def analyze(data):
    errors = []
    if data['failure']:
        errors.append(data['failure'])
    if len(data['trials']) != 16:
        errors.append('Expected four warm-ups and twelve measured trials.')
    if any(v['state'] != 'visible' for v in data['browser']['visibility']):
        errors.append('Browser was not visible throughout the run.')
    frames = data['frames']
    if not frames:
        errors.append('No engine FrameTiming samples were reported.')
    all_measured, all_gaps, all_lateness, trials = [], [], [], []
    for trial in data['trials']:
        actual = [s['index'] for s in trial['selections']]
        if actual != trial['expected_selections']:
            errors.append(f"Selection mismatch: {trial['scenario']} r{trial['repetition']}")
        if trial['warmup']:
            continue
        sample = [f for f in frames if trial['start_us'] <= f['vsyncStart'] <= trial['end_us']]
        if not sample:
            errors.append(f"Missing frame timings: {trial['scenario']} r{trial['repetition']}")
        gaps = animation_gaps(sample, trial['selections'])
        lateness = [e['actual_ms'] - e['planned_ms'] for e in trial['inputs']]
        all_measured.extend(sample)
        all_gaps.extend(gaps)
        all_lateness.extend(lateness)
        trials.append(dict(scenario=trial['scenario'], repetition=trial['repetition'],
                           selection=actual, frame_count=len(sample),
                           animation_cadence=distribution(gaps),
                           input_lateness=distribution(lateness)))
    return dict(valid=not errors, errors=errors,
                frame_cost={metric: distribution(f[metric+'_us']/1000 for f in all_measured)
                            for metric in ['build', 'raster', 'total']},
                animation_cadence=distribution(all_gaps),
                input_lateness=distribution(all_lateness), trials=trials,
                method='Raw Flutter FrameTiming in a release web build; warm-ups excluded. '
                'Cadence is adjacent engine vsync-start intervals inside each 750ms '
                'post-selection animation window. Large gaps retained. All costs are '
                'engine work/submission, not physical display presentation. 16.667ms '
                'is the chosen 60Hz comparison budget, not an inferred display rate.',
                browser=data['browser'], viewport=data['viewport'],
                device_pixel_ratio=data['device_pixel_ratio'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('raw', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.raw.read_text())
    result = analyze(data)
    result['raw_sha256'] = hashlib.sha256(args.raw.read_bytes()).hexdigest()
    result['analysis_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/'summary.json').write_text(json.dumps(result, indent=2))
    measured = [f for f in data['frames'] if any(not t['warmup'] and
                t['start_us'] <= f['vsyncStart'] <= t['end_us'] for t in data['trials'])]
    fig, ax = plt.subplots(figsize=(10, 4), layout='constrained')
    for metric in ['build', 'raster', 'total']:
        ax.plot([f[metric+'_us']/1000 for f in measured], label=metric, alpha=.8)
    ax.axhline(1000/60, color='black', linestyle='--', label='60Hz comparison budget')
    ax.set(xlabel='Engine frame in measured trials (idle gaps omitted)', ylabel='Milliseconds',
           title='Flutter release web: frame work/submission, not display presentation')
    ax.legend()
    fig.savefig(args.output/'frame-cost.png', dpi=150)
    plt.close(fig)
    print(json.dumps({k: v for k, v in result.items() if k not in ['trials', 'browser']}, indent=2))
    if not result['valid']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
