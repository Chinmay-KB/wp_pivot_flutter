"""Create and verify provenance-mapped H.264 evidence media without interpolation."""
from __future__ import annotations
import argparse, csv, hashlib, json, subprocess
from pathlib import Path
import imageio_ffmpeg
from PIL import Image

def sha256(path: Path) -> str: return hashlib.sha256(path.read_bytes()).hexdigest()

def make(trial: Path, output: Path, fps: int = 30) -> dict:
    if output.exists(): raise FileExistsError(f"fresh output required: {output}")
    output.mkdir(parents=True)
    with (trial / "frames.csv").open(encoding="utf-8") as file:
        rows = list(csv.DictReader(file))
    if not rows: raise ValueError("trial has no frames")
    starts = [float(row["capture_start_ms"]) for row in rows]; duration = starts[-1] - starts[0]
    mp4 = output / "clip.mp4"
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    process = subprocess.Popen([ffmpeg, "-y", "-f", "rawvideo", "-vcodec", "rawvideo", "-pix_fmt", "rgb24",
        "-s", "480x800", "-r", str(fps), "-i", "-", "-an", "-vcodec", "libx264", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", str(mp4)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    mapping = []
    index = 0
    for output_index in range(max(1, round(duration / 1000 * fps) + 1)):
        moment = output_index * 1000 / fps
        while index + 1 < len(rows) and starts[index + 1] - starts[0] <= moment: index += 1
        row = rows[index]; frame = trial / "frames" / f"{int(row['frame']):06d}.png"
        process.stdin.write(Image.open(frame).convert("RGB").tobytes()); mapping.append({"output_frame": output_index, "presentation_ms": moment,
            "source_frame": int(row["frame"]), "source_sha256": row["sha256"], "method": "hold-preceding-native-frame"})
    process.stdin.close(); stderr = process.stderr.read(); process.stdout.close(); process.stderr.close(); process.wait()
    if process.returncode: raise RuntimeError(stderr.decode("utf-8", errors="replace"))
    poster = output / "poster.png"; Image.open(trial / "frames" / "000000.png").save(poster)
    manifest = {"schema_version": 1, "source_trial": trial.name, "source_relative_frames": "frames/*.png", "encoded_fps": fps,
        "acquisition_note": "Encoded 30 fps is presentation metadata; each output frame holds a preceding acquired native frame and no interpolation was generated.",
        "dimensions": [480, 800], "duration_ms_from_host_acquisition": duration, "frame_map": mapping,
        "files": {"clip.mp4": sha256(mp4), "poster.png": sha256(poster)}}
    (output / "media-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8"); return manifest

def verify(output: Path) -> dict:
    manifest = json.loads((output / "media-manifest.json").read_text(encoding="utf-8")); mp4 = output / "clip.mp4"; poster = output / "poster.png"
    ok = mp4.stat().st_size < 10 * 1024 * 1024 and sha256(mp4) == manifest["files"]["clip.mp4"] and sha256(poster) == manifest["files"]["poster.png"]
    decoded = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-i", str(mp4), "-f", "null", "-"], capture_output=True)
    if decoded.returncode: ok = False
    probe = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-v", "info", "-i", str(mp4), "-vf", "showinfo", "-f", "null", "-"], capture_output=True, text=True)
    frames = probe.stderr.count(" n:") if probe.returncode == 0 else 0
    if frames != len(manifest["frame_map"]): ok = False
    with Image.open(poster) as poster_image:
        dimensions = list(poster_image.size)
    result = {"ok": ok, "decoded_frames": frames, "mapped_frames": len(manifest["frame_map"]), "size_bytes": mp4.stat().st_size, "dimensions": dimensions}
    (output / "media-verification.json").write_text(json.dumps(result, indent=2), encoding="utf-8"); return result

def main() -> None:
    p=argparse.ArgumentParser(); sub=p.add_subparsers(dest="command",required=True); a=sub.add_parser("make"); a.add_argument("trial",type=Path);a.add_argument("--output",type=Path,required=True);b=sub.add_parser("verify");b.add_argument("output",type=Path); args=p.parse_args()
    result=make(args.trial.resolve(),args.output.resolve()) if args.command=="make" else verify(args.output.resolve()); print(json.dumps(result if args.command=="verify" else {"frames":len(result["frame_map"])}))
if __name__ == "__main__": main()
