"""Inspect native evidence without treating encoded frame rate as observations.

Image tracking is independent of native TransformToVisual telemetry. Header
correlation uses the initial, fully visible 'second' label; marker coordinates
come from the reference scene's unique color squares. Clipped markers are not
reported as complete left-edge observations.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.signal import correlate
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

COLORS = [(27, 161, 226), (96, 169, 23), (240, 150, 9), (162, 0, 255)]

# A conservative rejection gate, not a promised accuracy bound. Six 60Hz frames
# of receipt spread cannot support a useful shared motion timeline. Title-area
# Touch.FrameReported callbacks in header-01 were buffered by over 600ms.
MAX_RECEIPT_SPREAD_MS = 100.0


def require_comparable_timing(quality):
    if quality['clock_alignment']['receipt_spread_ms'] > MAX_RECEIPT_SPREAD_MS:
        raise ValueError('Unqualified host/guest clock alignment: retain the trial '
                         'for layout/selection, not an aligned motion comparison.')


def read_csv(path):
    with path.open(newline='', encoding='utf-8-sig') as source:
        return list(csv.DictReader(source))


def marker_bounds(rgb, color):
    mask = np.max(np.abs(rgb.astype(np.int16) - np.asarray(color,dtype=np.int16)), axis=2) <= 2
    mask[:200] = False  # Exclude the full-width bar above the page title.
    yy, xx = np.where(mask)
    if len(xx) < 16 or yy.max() - yy.min() + 1 < 50:
        return None
    x, y, w, h = int(xx.min()), int(yy.min()), int(np.ptp(xx)+1), int(np.ptp(yy)+1)
    return dict(x=x, y=y, width=w, height=h,
                complete=(63 <= w <= 65 and 63 <= h <= 65 and x > 0 and x+w < rgb.shape[1]),
                left_censored=(x == 0 and w < 64))


def bar_left(rgb, color):
    """Infer translation from either visible edge of the known 432 px bar.

    This specifically assumes the fixed reference scene has no scale transform.
    Fractional antialiased edges carry approximately one-pixel uncertainty.
    """
    strip=rgb[166:170].astype(np.int16)
    columns=np.where(np.any(np.max(np.abs(strip-np.asarray(color,dtype=np.int16)),axis=2)<=2,axis=0))[0]
    if len(columns)<2:return None
    left,right=int(columns.min()),int(columns.max())
    return left if left>0 else right+1-432


def header_match(rgb, template):
    strip = rgb[41:137].mean(axis=2)
    centered = template - template.mean()
    numerator = correlate(strip, centered, mode='valid', method='fft').ravel()
    count = template.size
    width=template.shape[1]
    sums=np.r_[0,np.cumsum(strip.sum(axis=0))]
    squares_sum=np.r_[0,np.cumsum((strip**2).sum(axis=0))]
    total=sums[width:]-sums[:-width]
    squares=squares_sum[width:]-squares_sum[:-width]
    variance = np.maximum(0, squares-total**2/count)
    template_energy = np.sum(centered**2)
    if template_energy < 1:
        raise ValueError('Header reference has no usable contrast.')
    denominator = np.sqrt(variance * template_energy)
    # FFT roundoff in black patches must not become a high-scoring match.
    scores = np.divide(numerator,denominator,out=np.full_like(numerator,-1),where=variance > count*.01)
    x = int(np.argmax(scores))
    return x, float(scores[x])


def match_input_clocks(host, guest):
    """Match ordered equal phase/coordinate samples; retain receipt-delay spread.

    This is an approximate offset, not a hardware clock synchronization protocol.
    No affine drift fit is justified by these short recordings.
    """
    offsets, cursor = [], 0
    touches = [g for g in guest if g['event'] in ('Down', 'Move', 'Up')]
    for event in host:
        if event.get('event') != 'pointer':
            continue
        for j in range(cursor, len(touches)):
            touch = touches[j]
            if (touch['event'].lower() == event['phase'] and
                    float(touch['x']) == event['x'] and float(touch['y']) == event['y']):
                offsets.append(float(touch['t_ms']) - event['host_received_ms'])
                cursor = j + 1
                break
    if not offsets:
        raise ValueError('No corresponding host/guest input samples.')
    return dict(matched_samples=len(offsets), offset_ms=float(np.median(offsets)),
                offset_min_ms=min(offsets), offset_max_ms=max(offsets),
                receipt_spread_ms=float(np.ptp(offsets)), drift_estimated=False)


def analyze(directory, output):
    manifest = json.loads((directory/'manifest.json').read_text())
    frames = read_csv(directory/'frames.csv')
    inputs = read_csv(next(directory.rglob('inputs.csv')))
    telemetry = read_csv(next(directory.rglob('trajectory.csv')))
    host = [json.loads(line) for line in (directory/'events.jsonl').read_text().splitlines()]
    alignment = match_input_clocks(host, inputs)
    down = next(float(r['t_ms']) for r in inputs if r['event'] == 'Down')
    up = [float(r['t_ms']) for r in inputs if r['event'] == 'Up']
    initial = np.array(Image.open(directory/'frames'/'000000.png').convert('RGB'))
    template = initial[41:137, 158:379].mean(axis=2)
    observed, integrity = [], []
    for frame in frames:
        path = directory/'frames'/f"{int(frame['frame']):06d}.png"
        if hashlib.sha256(path.read_bytes()).hexdigest() != frame['sha256']:
            integrity.append(path.name)
        rgb = np.array(Image.open(path).convert('RGB'))
        start, end = float(frame['capture_start_ms']), float(frame['capture_end_ms'])
        time = (start+end)/2 + alignment['offset_ms'] - down
        x, score = header_match(rgb, template)
        row = dict(frame=int(frame['frame']), t_ms=time,
                   interval_start_ms=start+alignment['offset_min_ms']-down,
                   interval_end_ms=end+alignment['offset_max_ms']-down,
                   header_second_x=x if score >= .93 else None, header_correlation=score)
        for item, color in enumerate(COLORS):
            bounds = marker_bounds(rgb, color)
            row[f'marker_{item}_x'] = bounds['x'] if bounds and bounds['complete'] else None
            row[f'marker_{item}_visible_width'] = bounds['width'] if bounds else 0
            row[f'bar_{item}_x'] = bar_left(rgb,color)
        observed.append(row)
    output.mkdir(parents=True, exist_ok=True)
    with (output/'image_tracks.csv').open('w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=observed[0].keys())
        writer.writeheader(); writer.writerows(observed)

    header = [r for r in telemetry if r['item'] == '1' and np.isfinite(float(r['header_x']))]
    ht = np.array([float(r['t_ms'])-down for r in header])
    hx = np.array([float(r['header_x']) for r in header])
    checks, motion_checks = [], []
    for obs in observed:
        if obs['header_second_x'] is None or not len(ht): continue
        inside = (ht >= obs['interval_start_ms']) & (ht <= obs['interval_end_ms'])
        if not inside.any(): continue
        # An interval compatibility test, not a pointwise timing precision claim.
        low, high = hx[inside].min(), hx[inside].max()
        error = max(low-obs['header_second_x'], obs['header_second_x']-high, 0)
        checks.append(float(error))
        if high-low > .1: motion_checks.append(float(error))
    t = np.array([float(r['capture_start_ms']) for r in frames])
    times = np.unique([float(r['t_ms']) for r in telemetry])
    groups = {}
    for row in telemetry:
        groups.setdefault(row['t_ms'], []).append(row)
    aliases = sum(len({r['content_x'] for r in group if r['content_x'] != 'NaN'}) == 1
                  for group in groups.values())
    stats = dict(trial=directory.name, source=manifest['source'],
                 frame_count=len(frames), capture_fps=manifest['capture_fps'],
                 capture_interval_p50_ms=float(np.median(np.diff(t))),
                 capture_interval_p95_ms=float(np.percentile(np.diff(t),95)),
                 capture_interval_max_ms=float(np.max(np.diff(t))),
                 hashes_valid=not integrity, invalid_frames=integrity,
                 clock_alignment=alignment, actual_first_contact_ms=up[0]-down,
                 render_callback_interval_p50_ms=float(np.median(np.diff(times))) if len(times)>1 else None,
                 header_interval_check_count=len(checks),
                 header_interval_error_p95_px=float(np.percentile(checks,95)) if checks else None,
                 header_interval_error_max_px=max(checks) if checks else None,
                 header_motion_check_count=len(motion_checks),
                 header_motion_interval_error_p95_px=float(np.percentile(motion_checks,95)) if motion_checks else None,
                 marker_edge_uncertainty_px=1,
                 body_telemetry_aliased_callbacks=aliases,
                 body_telemetry_total_callbacks=len(groups),
                 body_telemetry_qualified=False,
                 coarse_alignment_accepted=alignment['receipt_spread_ms'] <= MAX_RECEIPT_SPREAD_MS,
                 qualification=('Image observations only; header telemetry assessed by interval compatibility. No physical display timing claim.'
                   if alignment['receipt_spread_ms'] <= MAX_RECEIPT_SPREAD_MS else
                   'REJECTED for aligned motion: buffered input callbacks make host/guest alignment unreliable. Layout and selection outcomes only.'))
    (output/'quality.json').write_text(json.dumps(stats,indent=2))
    # Actual guest events, normalized to a shared pre-roll, for Flutter replay.
    events = [dict(t_ms=float(r['t_ms'])-down+500, event=r['event'].lower(),
                   x=float(r['x']),y=float(r['y'])) for r in inputs if r['event'] in ('Down','Move','Up')]
    (output/'replay.json').write_text(json.dumps(dict(source_trial=directory.name,
        viewport=manifest['resolution'], events=events,
        selection_events=[dict(t_ms=float(r['t_ms'])-down+500,index=int(r['id']))
                          for r in inputs if r['event']=='selection' and float(r['t_ms'])>=down],
        end_ms=events[-1]['t_ms']+1400),indent=2))

    fig, axes = plt.subplots(3,1,figsize=(10,9),sharex=True,layout='constrained')
    if len(ht): axes[0].plot(ht,hx,color='#555555',label='Guest header telemetry',lw=1.3)
    oo = [r for r in observed if r['header_second_x'] is not None]
    axes[0].errorbar([r['t_ms'] for r in oo], [r['header_second_x'] for r in oo],
        xerr=np.array([[r['t_ms']-r['interval_start_ms'] for r in oo],
                       [r['interval_end_ms']-r['t_ms'] for r in oo]]),
        fmt='.',color='#1678a8',label='Image match + acquisition/receipt interval',capsize=1)
    axes[0].set_ylabel('Second header x (px)'); axes[0].legend(fontsize=8)
    for i,color in enumerate(COLORS):
        oo = [r for r in observed if r[f'bar_{i}_x'] is not None]
        axes[1].scatter([r['t_ms'] for r in oo],[r[f'bar_{i}_x'] for r in oo],
                        c=[np.array(color)/255],label=['first','second','third','fourth'][i],s=15)
    axes[1].set_ylabel('Page bar left (px)'); axes[1].legend(fontsize=8,ncol=4)
    touches=[r for r in inputs if r['event'] in ('Down','Move','Up')]
    axes[2].plot([float(r['t_ms'])-down for r in touches],[float(r['x']) for r in touches],'.-',color='black')
    axes[2].set_ylabel('Guest input x (px)'); axes[2].set_xlabel('Time since guest pointer down (ms)')
    for ax in axes:
        ax.axvline(0,color='#777777',ls=':',lw=.7)
        for u in up: ax.axvline(u-down,color='#777777',ls='--',lw=.7)
        ax.grid(alpha=.2)
        ax.set_xlim(-250,max(r['t_ms'] for r in observed))
    warning = '' if stats['coarse_alignment_accepted'] else ' — TIMING UNQUALIFIED'
    fig.suptitle(directory.name+' — native WP8.1 emulator'+warning+'\nDashed: callback release; dots are observations, not interpolated frames',fontsize=12)
    fig.savefig(output/'trajectories.png',dpi=150)
    plt.close(fig)
    return stats


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('session',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    summary=[]
    for directory in sorted(args.session.iterdir()):
        if directory.is_dir() and (directory/'manifest.json').exists():
            stats=analyze(directory,args.output/directory.name)
            summary.append(stats)
            print(json.dumps(stats))
    (args.output/'summary.json').write_text(json.dumps(summary,indent=2))


if __name__=='__main__':main()
