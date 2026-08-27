"""Encode real captured frames on an input-aligned common timeline.

30 fps is the delivery rate. Native acquisition is slower/irregular; frames are
held, never interpolated. Frame mappings make every video sample traceable.
No temporal stretching or per-component alignment is performed.
"""
import argparse
import csv
import json
import subprocess
from pathlib import Path
import imageio_ffmpeg
import numpy as np
from PIL import Image


def read_csv(path):
    with path.open(newline='') as source:return list(csv.DictReader(source))


def encode(directory, rows, times, output, frame_rate=30):
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    command=[ffmpeg,'-y','-loglevel','error','-f','rawvideo','-pix_fmt','rgb24',
             '-s','480x800','-r',str(frame_rate),'-i','-','-an','-c:v','libx264',
             '-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(output)]
    process=subprocess.Popen(command,stdin=subprocess.PIPE)
    indices=[]
    source_times=np.array([float(row['t_ms']) for row in rows])
    cache={}
    try:
        for t in times:
            index=int(np.clip(np.searchsorted(source_times,t,side='right')-1,0,len(rows)-1))
            frame=int(rows[index]['frame'])
            if frame not in cache:
                cache={frame:Image.open(directory/'frames'/f'{frame:06d}.png').convert('RGB').tobytes()}
            process.stdin.write(cache[frame]);indices.append(frame)
    finally:
        process.stdin.close()
    if process.wait():raise RuntimeError('ffmpeg encoding failed')
    return indices


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--native',type=Path,required=True)
    parser.add_argument('--analysis',type=Path,required=True)
    parser.add_argument('--flutter',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--font',type=Path,default=Path('C:/Windows/Fonts/segoeui.ttf'))
    args=parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    flutter_manifest=json.loads((args.flutter/'manifest.json').read_text())
    improved=flutter_manifest.get('variant')=='native-motion-implementation'
    flutter_video='flutter-improved.mp4' if improved else 'flutter-baseline.mp4'
    flutter_label='Flutter improved - test replay' if improved else 'Flutter 2.0 baseline - test replay'
    native=read_csv(args.analysis/'image_tracks.csv')
    flutter=read_csv(args.flutter/'frames.csv')
    start=max(-500,float(native[0]['t_ms']),float(flutter[0]['t_ms']))
    end=min(float(native[-1]['t_ms']),float(flutter[-1]['t_ms']))
    times=np.arange(start,end,1000/30)
    ni=encode(args.native,native,times,args.output/'native.mp4')
    fi=encode(args.flutter,flutter,times,args.output/flutter_video)
    # forward slashes + escaped drive colon for ffmpeg filter syntax.
    font=args.font.resolve().as_posix().replace(':','\\:')
    filtergraph=(f"[0:v]pad=iw:ih+56:0:56:black,drawtext=fontfile='{font}':text='Native WP8.1 emulator':"
                 "fontcolor=white:fontsize=22:x=16:y=14[n];"
                 f"[1:v]pad=iw:ih+56:0:56:black,drawtext=fontfile='{font}':text='{flutter_label}':"
                 "fontcolor=white:fontsize=22:x=16:y=14[f];[n][f]hstack=inputs=2[v]")
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-loglevel','error',
                    '-i',str(args.output/'native.mp4'),'-i',str(args.output/flutter_video),
                    '-filter_complex',filtergraph,'-map','[v]','-an','-c:v','libx264','-crf','18',
                    '-pix_fmt','yuv420p','-movflags','+faststart',str(args.output/'comparison.mp4')],check=True)
    replay=json.loads((args.analysis/'replay.json').read_text())
    pointer_filters=[]
    for event,next_event in zip(replay['events'],replay['events'][1:]):
        if event['event']=='up':continue
        begin=(event['t_ms']-500-start)/1000
        finish=(next_event['t_ms']-500-start)/1000
        for panel in (0,480):
            pointer_filters.append(f"drawbox=x={event['x']+panel-10}:y={event['y']+56-10}:"
                f"w=20:h=20:color=white@0.9:t=2:enable='gte(t,{begin})*lt(t,{finish})'")
    if pointer_filters:
        subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-loglevel','error',
            '-i',str(args.output/'comparison.mp4'),'-vf',','.join(pointer_filters),
            '-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',
            str(args.output/'comparison-annotated.mp4')],check=True)
    with (args.output/'video-frame-map.csv').open('w',newline='') as file:
        writer=csv.writer(file);writer.writerow(['video_frame','guest_time_since_down_ms','native_frame','flutter_frame'])
        writer.writerows(zip(range(len(times)),times,ni,fi))
    (args.output/'manifest.json').write_text(json.dumps(dict(
        native_trial=args.native.name,flutter_trial=args.flutter.name,delivery_fps=30,
        flutter_variant=flutter_manifest.get('variant'),
        source_sampling='Zero-order hold of captured PNGs; no interpolation, no time stretching.',
        alignment='Native midpoint acquisition time + median guest/host input offset; Flutter guest-event replay clock.',
        annotation='Separate annotated copy: white square follows last delivered guest touch point only while contact is down; source images/clean clips unchanged.',
        start_ms=start,end_ms=end,duration_seconds=len(times)/30,
        limitations='Native capture intervals and input receipt jitter limit temporal alignment; Flutter is deterministic engine output, not interactive performance.'
    ),indent=2))
    print(args.output/'comparison.mp4')


if __name__=='__main__':main()
