import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

import numpy as np
from PIL import Image


SPEC = importlib.util.spec_from_file_location(
    "analyze_micro_controls", Path(__file__).with_name("analyze_micro_controls.py")
)
analyzer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(analyzer)


class AnalyzeMicroControlsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def make_progress_trial(self) -> Path:
        trial = self.root / "progress_animation_pilot_r01"
        (trial / "frames").mkdir(parents=True)
        (trial / "guest" / "IsolatedStore").mkdir(parents=True)
        frame = trial / "frames" / "000000.png"
        Image.new("RGB", (480, 800), "black").save(frame)
        data = frame.read_bytes()
        with (trial / "frames.csv").open("w", newline="", encoding="utf-8") as file:
            writer = csv.DictWriter(file, fieldnames=("frame", "capture_start_ms", "capture_end_ms", "sha256", "bytes"))
            writer.writeheader()
            writer.writerow({"frame": 0, "capture_start_ms": 0, "capture_end_ms": 10,
                             "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})
        (trial / "manifest.json").write_text(json.dumps({
            "errors": [], "frame_count": 1, "resolution": [480, 800],
        }), encoding="utf-8")
        state_header = (
            "t_ms,event,slider_value,slider_x,slider_y,slider_width,slider_height,"
            "determinate_value,determinate_x,determinate_y,determinate_width,determinate_height,"
            "indeterminate_value,indeterminate_state,indeterminate_x,indeterminate_y,indeterminate_width,indeterminate_height,"
            "tilt_projection_present,tilt_rotation_x,tilt_rotation_y,tilt_global_offset_z,tilt_x,tilt_y,tilt_width,tilt_height\n"
        )
        state_row = "1,loaded,35,12,155,456,84,42,24,286,432,4,0,True,24,353,432,4,False,0,0,0,12,412,456,72\n"
        (trial / "guest" / "IsolatedStore" / "state.csv").write_text(state_header + state_row, encoding="utf-8")
        (trial / "guest" / "IsolatedStore" / "inputs.csv").write_text("t_ms,event,id,x,y\n", encoding="utf-8")
        return trial

    def test_corrupted_raw_png_is_rejected(self):
        trial = self.make_progress_trial()
        (trial / "frames" / "000000.png").write_bytes(b"corrupt")
        with self.assertRaisesRegex(ValueError, "integrity"):
            analyzer.verify_trial(trial)

    def test_empty_session_is_rejected_without_creating_output(self):
        session = self.root / "empty"
        session.mkdir()
        output = self.root / "analysis"
        with self.assertRaisesRegex(ValueError, "no trials"):
            analyzer.analyze_session(session, output)
        self.assertFalse(output.exists())

    def test_empty_frames_csv_is_rejected(self):
        trial = self.make_progress_trial()
        (trial / "frames.csv").write_text("frame,capture_start_ms,capture_end_ms,sha256,bytes\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "no observations"):
            analyzer.verify_trial(trial)

    def test_fractional_mark_preserves_four_by_four_logical_area(self):
        pixels = np.zeros((800, 480, 3), dtype=np.uint8)
        # A 4 px rectangle translated to x=56.8 covers five raster columns.
        alphas = ((56, .2), (57, 1), (58, 1), (59, 1), (60, .8))
        for x, alpha in alphas:
            pixels[353:357, x, 2] = round(255 * alpha)
        marks = analyzer.indeterminate_components(pixels)
        self.assertEqual(len(marks), 1)
        self.assertAlmostEqual(marks[0]["alpha_area_px2"], 16, places=6)
        self.assertAlmostEqual(marks[0]["logical_width_px"], 4, places=6)
        self.assertAlmostEqual(marks[0]["center_x_px"], 58.8, places=6)
        self.assertTrue(marks[0]["full_mark"])

    def test_exact_slider_and_progress_geometry(self):
        pixels = np.zeros((800, 480, 3), dtype=np.uint8)
        pixels[177:189, 24:171] = analyzer.ACCENT
        pixels[177:189, 183:456] = analyzer.TRACK
        pixels[171:195, 171:183] = analyzer.WHITE
        pixels[286:290, 36:207] = analyzer.ACCENT
        pixels[286:290, 207:444] = analyzer.PROGRESS_TRACK
        slider = analyzer.slider_geometry(pixels)
        progress = analyzer.determinate_geometry(pixels)
        self.assertEqual(slider["track_bbox"], [24, 177, 456, 189])
        self.assertEqual(slider["thumb_bbox"], [171, 171, 183, 195])
        self.assertAlmostEqual(slider["image_value"], 35)
        self.assertEqual(progress["track_bbox"], [36, 286, 444, 290])
        self.assertEqual(progress["fill_width_px"], 171)


if __name__ == "__main__":
    unittest.main()
