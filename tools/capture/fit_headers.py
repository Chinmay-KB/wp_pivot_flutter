"""Exploratory header model: fit first two runs, check the third without refitting.

Not a claim about native source constants. Coordinates come from guest telemetry;
the separate image/telemetry qualification must accompany any use of these fits.
"""
import argparse
import csv
import json
from pathlib import Path
import numpy as np
from scipy.optimize import least_squares
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def rows(path):
    with path.open(newline='') as file:return list(csv.DictReader(file))


def transition(directory):
    events=rows(next(directory.rglob('inputs.csv')))
    down=next(float(r['t_ms']) for r in events if r['event']=='Down')
    selection=[r for r in events if r['event']=='selection' and float(r['t_ms'])>down]
    if len(selection)!=1:return None
    anchor=float(selection[0]['t_ms']);item=selection[0]['id']
    data=[r for r in rows(next(directory.rglob('trajectory.csv'))) if r['item']==item]
    before=[r for r in data if float(r['t_ms'])<=anchor]
    if not before:return None
    start=float(before[-1]['header_x'])
    data=[r for r in data if 0<=float(r['t_ms'])-anchor<=450]
    t=np.array([float(r['t_ms'])-anchor for r in data])
    x=np.array([float(r['header_x']) for r in data])
    if not len(t) or abs(start-21)<2:return None
    return t,(start-x)/(start-21),start-21


def power(t,duration,exponent):
    return 1-(1-np.clip(t/duration,0,1))**exponent


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('session',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    results={}
    fig,axes=plt.subplots(1,2,figsize=(12,4),layout='constrained')
    for ax,scenario in zip(axes,('header_next','header_skip')):
        trials=[transition(args.session/f'{scenario}_r{i:02d}') for i in (1,2,3)]
        if any(t is None for t in trials):raise ValueError('Expected one observed selection per tap trial.')
        t=np.concatenate([r[0] for r in trials[:2]])
        y=np.concatenate([r[1] for r in trials[:2]])
        fit=least_squares(lambda p:power(t,*p)-y,[250,1],bounds=([150,.5],[400,3]))
        tt,yy,travel=trials[2]
        residual=(power(tt,*fit.x)-yy)*travel
        results[scenario]=dict(model='1 - (1 - clamp(t / duration, 0, 1)) ** exponent',
            time_origin='guest SelectionChanged callback',fit_trials=[1,2],held_out_trial=3,
            duration_ms=float(fit.x[0]),exponent=float(fit.x[1]),
            held_out_rmse_px=float(np.sqrt(np.mean(residual**2))),
            held_out_max_error_px=float(np.max(np.abs(residual))),
            observed_first_settled_samples_ms=[float(r[0][np.where(r[1]>=.999)[0][0]]) for r in trials],
            not_native_source_constants=True)
        for i,(tx,yx,_) in enumerate(trials):ax.scatter(tx,yx,s=11,label=f'Run {i+1}'+(' (held out)' if i==2 else ''),alpha=.7)
        grid=np.linspace(0,450,400)
        ax.plot(grid,power(grid,*fit.x),color='black',label='Fit to runs 1–2',lw=1.2)
        ax.set_title(scenario);ax.set_xlabel('Since selection callback (ms)');ax.set_ylabel('Normalized header travel')
        ax.grid(alpha=.2);ax.legend(fontsize=8)
    fig.suptitle('Exploratory native header fits — timing qualification still applies')
    fig.savefig(args.output/'header-fits.png',dpi=150);plt.close(fig)
    (args.output/'header-fits.json').write_text(json.dumps(results,indent=2))
    print(json.dumps(results,indent=2))


if __name__=='__main__':main()
