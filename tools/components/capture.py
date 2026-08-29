"""Capture explicit component pilot plans through Glance under an external device lease.

This supplies capture provenance, not a qualified motion/clock adapter. Native
fixtures must already be installed. Check each initial frame and guest state.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid
import zipfile
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'tools' / 'capture'))
from record_native import record_trial, save_json


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def viewport_size(plan):
    """Logical capture bounds. Defaults keep existing 480x800 plans valid."""
    ref = plan.get('reference_viewport', [480, 800])
    if not isinstance(ref, list) or len(ref) != 2:
        raise ValueError('reference_viewport must be [width, height].')
    width, height = ref
    if isinstance(width, bool) or isinstance(height, bool):
        raise ValueError('Invalid reference_viewport')
    if not isinstance(width, (int, float)) or not isinstance(height, (int, float)):
        raise ValueError('Invalid reference_viewport')
    if not math.isfinite(width) or not math.isfinite(height) or width < 1 or height < 1:
        raise ValueError('Invalid reference_viewport')
    return float(width), float(height)


def validate_plan(plan):
    uuid.UUID(plan['product_id'])
    if not isinstance(plan.get('control'), str) or not plan['control'].strip():
        raise ValueError('Plan must name the actual native control.')
    for key in ('pre_roll_seconds', 'post_roll_seconds'):
        value = plan[key]
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not 0 <= value <= 10:
            raise ValueError(f'Invalid bounded duration: {key}')
    width, height = viewport_size(plan)
    scenarios = plan['scenarios']
    if not isinstance(scenarios, list) or not 1 <= len(scenarios) <= 30:
        raise ValueError('Plan needs 1-30 scenarios.')
    identifiers = set()
    for scenario in scenarios:
        name = scenario['id']
        if not isinstance(name, str) or not re.fullmatch(r'[a-zA-Z0-9_-]{1,64}', name) or name in identifiers:
            raise ValueError('Unsafe or duplicate scenario identifier.')
        identifiers.add(name)
        actions = scenario['actions']
        if not isinstance(actions, list) or not 1 <= len(actions) <= 30:
            raise ValueError('Scenario needs 1-30 actions.')
        for action in actions + scenario.get('cleanup_actions', [{'op': 'key', 'name': 'back'}]):
            op = action['op']
            if op not in ('tap', 'swipe', 'wait', 'key'):
                raise ValueError(f'Unsupported pilot action: {op}')
            if op in ('tap', 'swipe'):
                for key, bound in [('x', width), ('y', height)] + ([('x1', width), ('y1', height)] if op == 'swipe' else []):
                    value = action[key]
                    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not 0 <= value < bound:
                        raise ValueError(f'Invalid coordinate {key}')
            if op == 'swipe' and (type(action['ms']) is not int or not 20 <= action['ms'] <= 5000):
                raise ValueError('Invalid swipe duration.')
            if op == 'wait':
                value = action['seconds']
                if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not 0 <= value <= 10:
                    raise ValueError('Invalid wait duration.')
            if op == 'key' and action.get('name') != 'back':
                raise ValueError('Only Back is supported in pilot plans.')
    return plan


def package_product(package):
    with zipfile.ZipFile(package) as archive:
        name = next(n for n in archive.namelist() if n.lower() == 'wmappmanifest.xml')
        root = ET.fromstring(archive.read(name))
    app = next(node for node in root.iter() if node.tag.split('}')[-1] == 'App')
    return str(uuid.UUID(app.attrib['ProductID'].strip('{}')))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--glance-app', required=True, type=Path)
    p.add_argument('--plan', required=True, type=Path)
    p.add_argument('--package', required=True, type=Path)
    p.add_argument('--source', required=True, type=Path)
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--only', nargs='+')
    p.add_argument('--repetitions', type=int, choices=range(1, 6), default=1)
    args = p.parse_args()
    plan = validate_plan(json.loads(args.plan.read_text(encoding='utf-8-sig')))
    if args.output.exists():
        p.error('Output already exists; preserve it and choose a new attempt.')
    if package_product(args.package) != str(uuid.UUID(plan['product_id'])):
        p.error('Package and plan product IDs do not match.')
    selected = [s for s in plan['scenarios'] if not args.only or s['id'] in args.only]
    if not selected or args.only and set(args.only) - {s['id'] for s in selected}:
        p.error('Scenario filter is empty or includes unknown IDs.')
    source = args.source.resolve(strict=True)
    provenance = {
        'repository_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip(),
        'reference_source_sha256': {str(f.relative_to(source)): digest(f) for f in source.rglob('*')
                                    if f.is_file() and not {'bin', 'obj', 'packages'}.intersection(f.relative_to(source).parts)},
        'expected_installed_package_sha256': digest(args.package),
        'package_identity_note': 'Expected deployed package, not guest readback proof.',
        'scenario_plan_sha256': digest(args.plan),
        'recorder_sha256': digest(__file__),
        'capture_core_sha256': digest(REPO / 'tools/capture/record_native.py'),
        'glance_source_sha256': {name: digest(args.glance_app / 'wpmirror' / name) for name in ('emulator.py', 'xde_bridge.ps1')},
        'qualification': 'pilot-only; no aligned native/Flutter motion comparison or hardware latency claim',
    }
    sys.path.insert(0, str(args.glance_app.resolve()))
    from wpmirror.emulator import XdeBridge, launch_app, deployment_targets, sdk_paths
    capture, control = XdeBridge(), XdeBridge()
    args.output.mkdir(parents=True)
    save_json(args.output / 'plan.json', plan)
    try:
        status = capture.call('status')
        if not status.get('ready'):
            raise RuntimeError(f'Emulator not ready: {status}')
        control.call('status')
        # Glance's XdeBridge attaches to the WVGA 512MB VM by name. Live
        # capture cannot retarget WXGA/720p/1080p from this script alone.
        target = next(t for t in deployment_targets() if t['name'] == 'Emulator 8.1 WVGA 4 inch 512MB')
        isetool = sdk_paths()['deploy'].parent.parent / 'IsolatedStorageExplorerTool/ISETool.exe'
        for scenario in selected:
            for repeat in range(args.repetitions):
                launch = launch_app(plan['product_id'])
                time.sleep(1)
                directory = args.output / f"{scenario['id']}_r{repeat+1:02d}"
                manifest = record_trial(capture, control, scenario, directory,
                                        plan['pre_roll_seconds'], plan['post_roll_seconds'],
                                        {**status, 'launch': launch}, provenance, plan['control'])
                manifest['initial_state_verified'] = False
                manifest['initial_state_note'] = 'Inspect original first frames and guest state; launch success is not proof of reset.'
                save_json(directory / 'manifest.json', manifest)
                cleanup = []
                for action in scenario.get('cleanup_actions', [{'op': 'key', 'name': 'back'}]):
                    if action['op'] == 'wait':
                        time.sleep(action['seconds'])
                        cleanup.append({'action': action, 'wait_completed': True})
                    else:
                        cleanup.append({'action': action, 'result': control.call(**action)})
                    time.sleep(.2)
                save_json(directory / 'cleanup.json', cleanup)
                export = directory / 'guest'
                export.mkdir()
                result = subprocess.run([str(isetool), 'ts', f"deviceindex:{target['index']}", plan['product_id'], str(export.resolve())],
                                        capture_output=True, text=True, timeout=30)
                (directory / 'guest-export.log').write_text(result.stdout + result.stderr, encoding='utf-8')
                guest = list(export.rglob('state.csv'))
                save_json(directory / 'guest-export.json', {'returncode': result.returncode, 'state_files': [str(f.relative_to(directory)) for f in guest]})
                if result.returncode or not guest:
                    raise RuntimeError('Guest state export failed. Preserve pilot and inspect before retrying.')
    except BaseException as exc:
        save_json(args.output / 'failure.json', {'type': type(exc).__name__, 'error': str(exc)})
        raise
    finally:
        capture.close()
        control.close()


if __name__ == '__main__':
    main()
