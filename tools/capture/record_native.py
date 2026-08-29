"""Record original native PNGs, host timing intervals and SDK pointer events.

Requires the Glance checkout's app directory and installed WP SDK. Does not infer
guest frame times from an MP4 playback rate. Each scenario gets a fresh app launch.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import io
import json
import platform
import queue
import subprocess
import sys
import threading
import time
from pathlib import Path
from PIL import Image


def save_json(path, value):
    path.write_text(json.dumps(value, indent=2), encoding='utf-8')


def record_trial(capture, control, scenario, directory, pre_roll, post_roll, app_status, provenance):
    directory.mkdir(parents=True, exist_ok=False)
    frame_dir = directory / 'frames'
    frame_dir.mkdir()
    started = time.perf_counter_ns()
    def now(): return (time.perf_counter_ns()-started)/1e6
    frames, events, errors = [], [], []
    pending = queue.Queue(maxsize=180)
    stopped = threading.Event()
    width = height = None

    def write_frames():
        while True:
            item = pending.get()
            if item is None: return
            number, data = item
            try: (frame_dir / f'{number:06d}.png').write_bytes(data)
            except Exception as exc: errors.append(str(exc)); stopped.set()

    def acquire():
        nonlocal width, height
        try:
            while not stopped.is_set():
                before = now()
                result = capture.call('capture', file=True)
                data = Path(result['path']).read_bytes()
                after = now()
                if width is None:
                    with Image.open(io.BytesIO(data)) as image: width, height = image.size
                number = len(frames)
                pending.put((number, data), timeout=2)
                frames.append({'frame':number, 'capture_start_ms':before, 'capture_end_ms':after,
                               'sha256':hashlib.sha256(data).hexdigest(), 'bytes':len(data)})
        except Exception as exc:
            errors.append(str(exc)); stopped.set()

    previous_handler = control.event_handler
    control.event_handler = lambda event: events.append({'host_received_ms':now(), **event})
    writer = threading.Thread(target=write_frames, daemon=True)
    producer = threading.Thread(target=acquire, daemon=True)
    writer.start(); producer.start()
    try:
        time.sleep(pre_roll)
        for action in scenario['actions']:
            if errors: raise RuntimeError(errors)
            if action['op'] == 'wait':
                time.sleep(action['seconds']); continue
            events.append({'host_received_ms':now(), 'event':'request', **action})
            result = control.call(**action)
            events.append({'host_received_ms':now(), 'event':'response', 'result':result})
        time.sleep(post_roll)
    except Exception as exc:
        errors.append(str(exc))
    finally:
        stopped.set()
        producer.join(25)
        pending.put(None, timeout=3)
        writer.join(10)
        control.event_handler = previous_handler
    if producer.is_alive() or writer.is_alive(): errors.append('Capture worker failed to stop.')
    with (directory/'frames.csv').open('w', newline='', encoding='utf-8') as file:
        output = csv.DictWriter(file, fieldnames=['frame','capture_start_ms','capture_end_ms','sha256','bytes'])
        output.writeheader(); output.writerows(frames)
    (directory/'events.jsonl').write_text(''.join(json.dumps(e)+'\n' for e in events), encoding='utf-8')
    times = [f['capture_start_ms'] for f in frames]
    changed = sum(a['sha256'] != b['sha256'] for a,b in zip(frames,frames[1:]))
    manifest = {
        'schema_version':1, 'source':'native-windows-phone-emulator',
        'control':'Microsoft.Phone.Controls.Pivot (Silverlight WP8.0 app on WP8.1 OS)',
        'scenario':scenario, 'native_status':app_status,
        'resolution':[width,height], 'host':platform.platform(),
        'capture_backend':'Microsoft.Xde.Interface.AutomationClient.CaptureImage',
        'timestamp_semantics':'Host monotonic intervals around capture call + file read, not guest presentation timestamps.',
        'pointer_timestamp_semantics':'Host receipt after SDK SendMouseEvent returns, not physical touch latency.',
        'clean_source':True, 'frame_count':len(frames), 'consecutive_changed_frames':changed,
        'provenance':provenance,
        'capture_fps':(len(times)-1)*1000/(times[-1]-times[0]) if len(times)>1 else 0,
        'max_interval_ms':max((b-a for a,b in zip(times,times[1:])),default=0),
        'errors':errors, 'outcome':'failed' if errors else 'captured-not-yet-analyzed'
    }
    save_json(directory/'manifest.json',manifest)
    if errors: raise RuntimeError(errors)
    print(json.dumps({'trial':directory.name, 'frames':len(frames), 'capture_fps':manifest['capture_fps']}),flush=True)
    return manifest


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--glance-app',type=Path,required=True)
    parser.add_argument('--plan',type=Path,default=Path(__file__).with_name('pivot_scenarios.json'))
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--repetitions',type=int,default=3)
    parser.add_argument('--only',nargs='*')
    parser.add_argument('--label',default='trajectory-on')
    args=parser.parse_args()
    if args.output.exists(): raise SystemExit('Output exists; choose a new session path.')
    sys.path.insert(0,str(args.glance_app.resolve()))
    from wpmirror.emulator import XdeBridge, launch_app, deployment_targets, sdk_paths
    plan=json.loads(args.plan.read_text())
    repo=Path(__file__).resolve().parents[2]
    package=repo/'tools/native_pivot/bin/Release/PivotReference.xap'
    sources={str(p.relative_to(repo)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
             for p in (repo/'tools/native_pivot').rglob('*')
             if p.is_file() and not {'bin','obj'}.intersection(p.relative_to(repo).parts)}
    revision=subprocess.run(['git','rev-parse','HEAD'],cwd=repo,capture_output=True,text=True,check=True).stdout.strip()
    provenance=dict(label=args.label,reference_source_sha256=sources,repository_commit=revision,
                    expected_installed_package_sha256=hashlib.sha256(package.read_bytes()).hexdigest(),
                    package_identity_note='Hash of the package built/deployed before this run; not read back from the guest.',
                    recorder_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    provenance['glance_source_sha256']={name:hashlib.sha256((args.glance_app/'wpmirror'/name).read_bytes()).hexdigest()
                                       for name in ['emulator.py','xde_bridge.ps1']}
    provenance['scenario_plan_sha256']=hashlib.sha256(args.plan.read_bytes()).hexdigest()
    target=next(t for t in deployment_targets() if t['name']=='Emulator 8.1 WVGA 4 inch 512MB')
    isetool=sdk_paths()['deploy'].parent.parent/'IsolatedStorageExplorerTool/ISETool.exe'
    args.output.mkdir(parents=True)
    save_json(args.output/'plan.json',plan)
    capture,control=XdeBridge(),XdeBridge()
    try:
        status=capture.call('status')
        assert status['ready'],status
        control.call('status')
        launch_app(plan['product_id'])
        time.sleep(.5)
        control.call('key',name='back')
        for scenario in plan['scenarios']:
            if args.only and scenario['id'] not in args.only: continue
            for repeat in range(args.repetitions):
                launch_app(plan['product_id'])
                time.sleep(.8)
                directory=args.output/f"{scenario['id']}_r{repeat+1:02d}"
                record_trial(capture,control,scenario,directory,plan['pre_roll_seconds'],plan['post_roll_seconds'],status,provenance)
                control.call('key',name='back')  # App flushes its passive telemetry.
                export=directory/'guest'
                export.mkdir()
                result=subprocess.run([str(isetool),'ts',f"deviceindex:{target['index']}",plan['product_id'],str(export.resolve())],
                                      capture_output=True,text=True,timeout=30)
                (directory/'guest-export.log').write_text(result.stdout+result.stderr,encoding='utf-8')
                if result.returncode or not list(export.rglob('trajectory.csv')):
                    raise RuntimeError('Native telemetry export failed: '+result.stdout+result.stderr)
    finally:
        capture.close(); control.close()


if __name__=='__main__': main()
