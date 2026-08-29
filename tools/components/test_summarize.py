import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import imageio_ffmpeg
from PIL import Image

spec = importlib.util.spec_from_file_location('component_summary', Path(__file__).with_name('summarize.py'))
summary = importlib.util.module_from_spec(spec)
spec.loader.exec_module(summary)
replay_spec = importlib.util.spec_from_file_location('replay_video', Path(__file__).with_name('replay_video.py'))
replay_video = importlib.util.module_from_spec(replay_spec)
replay_spec.loader.exec_module(replay_video)


class SummaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.trial = Path(self.temp.name) / 'trial'
        (self.trial / 'frames').mkdir(parents=True)
        self.output = Path(self.temp.name) / 'derived'
        self.rows = []
        for i, color in enumerate(('red', 'blue')):
            path = self.trial / 'frames' / f'{i:06d}.png'
            Image.new('RGB', (16, 16), color).save(path)
            data = path.read_bytes()
            self.rows.append({'frame': i, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                              'capture_start_ms': i * 100, 'capture_end_ms': i * 100 + 20})
        (self.trial / 'manifest.json').write_text(json.dumps({
            'errors': [], 'frame_count': 2, 'resolution': [16, 16], 'control': 'test', 'capture_fps': 10}))
        self.write_rows()

    def write_rows(self):
        with (self.trial / 'frames.csv').open('w', newline='') as file:
            table = csv.DictWriter(file, fieldnames=list(self.rows[0]))
            table.writeheader()
            table.writerows(self.rows)

    def test_video_holds_observed_frames_and_decodes(self):
        report = summary.summarize(self.trial, self.output, fps=30)
        self.assertEqual(report['encoded_frames'], 4)
        self.assertFalse(report['qualified_for_aligned_motion'])
        with (self.output / 'video-frame-map.csv').open() as file:
            mapping = list(csv.DictReader(file))
        self.assertEqual([int(row['source_frame']) for row in mapping], [0, 0, 0, 1])
        result = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error', '-i',
                                 str(self.output / 'native.mp4'), '-f', 'null', '-'], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_corrupted_raw_bytes_rejected(self):
        (self.trial / 'frames/000000.png').write_bytes(b'corrupted')
        with self.assertRaises(ValueError):
            summary.summarize(self.trial, self.output)
        self.assertFalse(self.output.exists())

    def test_overlapping_acquisition_rejected(self):
        self.rows[1]['capture_start_ms'] = 10
        self.write_rows()
        with self.assertRaises(ValueError):
            summary.summarize(self.trial, self.output)

    def test_unindexed_frame_rejected(self):
        (self.trial / 'frames/unindexed.png').write_bytes(b'extra')
        with self.assertRaises(ValueError):
            summary.summarize(self.trial, self.output)

    def test_existing_output_and_bad_fps_rejected(self):
        for fps in (0, 121, True, float('nan')):
            with self.subTest(fps=fps), self.assertRaises(ValueError):
                summary.summarize(self.trial, self.output, fps=fps)
        self.output.mkdir()
        with self.assertRaises(ValueError):
            summary.summarize(self.trial, self.output)

    def test_replay_video_and_invalid_cadence(self):
        path = self.trial / 'frames.csv'
        path.write_text('frame,t_ms\n0,0\n1,33.333\n')
        report = replay_video.encode(self.trial, self.output)
        self.assertEqual(len(report['frames']), 2)
        self.assertTrue(report['fully_decoded'])
        for timestamp in ('34', 'nan'):
            path.write_text(f'frame,t_ms\n0,0\n1,{timestamp}\n')
            with self.assertRaises(ValueError):
                replay_video.encode(self.trial, Path(self.temp.name) / 'invalid')


if __name__ == '__main__':
    unittest.main()
