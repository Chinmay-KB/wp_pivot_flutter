"""Compare visible page motion at native acquisition times, without time warping.

Each renderer's bar geometry is calibrated from its first resting image. This
supports the legacy baseline's different padding/header height. A missing page is
a visibility mismatch, never a zero positional error. Capture intervals are an
alignment sensitivity check, not a proven presentation-time confidence bound.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from analyze_native import COLORS, read_csv, require_comparable_timing


def color_mask(rgb, color):
    return np.max(np.abs(rgb.astype(np.int16)-np.asarray(color, dtype=np.int16)), axis=2) <= 2


def calibrate_bar(rgb):
    mask = color_mask(rgb, COLORS[0])
    # Only this fixed reference scene is supported; exclude the square marker.
    counts = mask[100:250].sum(axis=1)
    y = int(np.argmax(counts))+100
    xx = np.flatnonzero(mask[y])
    if len(xx) < 300 or xx[0] == 0 or xx[-1] == rgb.shape[1]-1:
        raise ValueError('First image must contain an unclipped resting blue bar.')
    return dict(x=int(xx[0]), y=y, width=int(xx[-1]-xx[0]+1))


def track_bar(rgb, geometry, color):
    xx = np.flatnonzero(color_mask(rgb[geometry['y']:geometry['y']+1], color)[0])
    if len(xx) < 2:
        return None
    left, right = int(xx[0]), int(xx[-1])
    return left if left > 0 else right+1-geometry['width']


def sample_error(native, flutter):
    shared = [abs(a-b) for a,b in zip(native, flutter) if a is not None and b is not None]
    visibility_mismatch = any((a is None) != (b is None) for a,b in zip(native, flutter))
    return shared, visibility_mismatch


def describe(values):
    return dict(count=len(values), mae_px=float(np.mean(values)) if values else None,
                p95_px=float(np.percentile(values,95)) if values else None,
                max_px=float(max(values)) if values else None)


def compare(native_dir, analysis, flutter_dir, output):
    require_comparable_timing(json.loads((analysis/'quality.json').read_text()))
    native_rows = read_csv(analysis/'image_tracks.csv')
    flutter_rows = read_csv(flutter_dir/'frames.csv')
    manifest = json.loads((flutter_dir/'manifest.json').read_text())
    output.mkdir(parents=True, exist_ok=True)
    def read_image(directory, frame):
        return np.array(Image.open(directory/'frames'/f'{int(frame):06d}.png').convert('RGB'))
    native_geometry = calibrate_bar(read_image(native_dir, native_rows[0]['frame']))
    flutter_geometry = calibrate_bar(read_image(flutter_dir, flutter_rows[0]['frame']))
    ft = np.array([float(row['t_ms']) for row in flutter_rows])
    ftracks = []
    for row in flutter_rows:
        rgb=read_image(flutter_dir,row['frame'])
        ftracks.append([track_bar(rgb,flutter_geometry,color) for color in COLORS])
    results, errors, interval_errors, moving_errors = [], [], [], []
    visibility_count = interval_visibility_count = moving_count = compared_count = 0
    for row in native_rows:
        t = float(row['t_ms'])
        if t < 0 or t > ft[-1]:
            continue
        n = [float(row[f'bar_{i}_x']) if row[f'bar_{i}_x'] else None for i in range(4)]
        j = int(np.clip(np.searchsorted(ft,t,side='right')-1,0,len(ft)-1))
        f = ftracks[j]
        shared, mismatch = sample_error(n,f)
        lo,hi = float(row['interval_start_ms']),float(row['interval_end_ms'])
        # Include the held Flutter sample at the start of the interval.
        a = max(0,int(np.searchsorted(ft,lo,side='right')-1))
        b = min(len(ft),int(np.searchsorted(ft,hi,side='right')))
        candidates = ftracks[a:max(a+1,b)]
        interval_mismatch = all(sample_error(n,c)[1] for c in candidates)
        bounds_errors = []
        for i,x in enumerate(n):
            if x is None:
                continue
            xs = [c[i] for c in candidates if c[i] is not None]
            if xs:
                bounds_errors.append(max(min(xs)-x,x-max(xs),0))
        moving = mismatch or is_moving(n,native_geometry['x']) or is_moving(f,flutter_geometry['x'])
        errors.extend(shared)
        interval_errors.extend(bounds_errors)
        if moving:
            moving_errors.extend(shared)
            moving_count += 1
        visibility_count += mismatch
        interval_visibility_count += interval_mismatch
        compared_count += 1
        result = dict(native_frame=int(row['frame']),t_ms=t,
                      interval_start_ms=lo,interval_end_ms=hi,
                      flutter_frame=int(flutter_rows[j]['frame']),flutter_t_ms=float(ft[j]),
                      motion_sample=moving,visibility_mismatch=mismatch,
                      interval_visibility_mismatch=interval_mismatch)
        for i in range(4):
            result[f'native_{i}_x'],result[f'flutter_{i}_x']=n[i],f[i]
        results.append(result)
    with (output/'comparison_tracks.csv').open('w',newline='') as file:
        writer=csv.DictWriter(file,fieldnames=results[0].keys())
        writer.writeheader();writer.writerows(results)
    report=dict(native_trial=native_dir.name,flutter_variant=manifest['variant'],
                native_layout=native_geometry,flutter_layout=flutter_geometry,
                layout_delta_px={key:flutter_geometry[key]-native_geometry[key] for key in native_geometry},
                sampled_native_frames=compared_count,motion_sample_frames=moving_count,
                shared_visible_position_error=describe(errors),
                motion_only_shared_visible_position_error=describe(moving_errors),
                interval_compatible_position_error=describe(interval_errors),
                visibility_mismatch_frames=visibility_count,
                visibility_mismatch_fraction=visibility_count/compared_count,
                interval_visibility_mismatch_frames=interval_visibility_count,
                source_hashes={str(path.name):hashlib.sha256(path.read_bytes()).hexdigest() for path in
                    [analysis/'image_tracks.csv',flutter_dir/'manifest.json',flutter_dir/'frames.csv',Path(__file__)]},
                method='Each native acquisition midpoint compared with latest preceding Flutter PNG. No interpolation or retiming. Equal weight per acquired native image; post-input observations only.',
                motion_filter='Either source has non-resting bar translation or visible-page sets differ.',
                limitations='Position errors include only mutually visible pages; visibility mismatches are reported separately. Native timing is uncertain. Interval metrics use acquisition plus receipt-spread intervals as sensitivity analysis, not certified display latency bounds. Bar edge precision is about 1px; typography and interactive runtime performance are not measured here.')
    (output/'metrics.json').write_text(json.dumps(report,indent=2))
    fig,axes=plt.subplots(2,1,figsize=(10,7),sharex=True,layout='constrained')
    for i,color in enumerate(COLORS):
        rgb=np.array(color)/255
        for source,style in [('native','o'),('flutter','-')]:
            rows=[r for r in results if r[f'{source}_{i}_x'] is not None]
            axes[0].plot([r['t_ms'] for r in rows],[r[f'{source}_{i}_x'] for r in rows],style,
                         color=rgb,ms=3,label=f'{source} page {i+1}')
    axes[0].set_ylabel('Visible page bar left (px)')
    axes[0].legend(ncol=4,fontsize=8)
    axes[0].set_title(f'{native_dir.name}: native observations / {manifest["variant"]}')
    axes[1].step([r['t_ms'] for r in results],[int(r['visibility_mismatch']) for r in results],where='post',label='Midpoint visibility mismatch')
    axes[1].step([r['t_ms'] for r in results],[int(r['interval_visibility_mismatch']) for r in results],where='post',label='Mismatch throughout alignment interval')
    axes[1].set_yticks([0,1],['Same pages','Different pages'])
    axes[1].set_xlabel('Time since first guest pointer down (ms)')
    axes[1].legend(fontsize=8)
    fig.savefig(output/'motion-comparison.png',dpi=150)
    plt.close(fig)
    return report


def is_moving(positions, rest):
    return any(x is not None and abs(x-rest)>1 for x in positions)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    for name in ['native','analysis','flutter','output']:
        parser.add_argument('--'+name,type=Path,required=True)
    args=parser.parse_args()
    print(json.dumps(compare(args.native,args.analysis,args.flutter,args.output),indent=2))
