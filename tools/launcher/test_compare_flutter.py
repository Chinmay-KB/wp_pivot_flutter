import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from compare_flutter import TILE_EXPECTATIONS, compare, rgb


class CompareFlutterTest(unittest.TestCase):
    def fixture(self, root: Path, shift_name: str | None = None) -> tuple[Path, Path]:
        frame = root / "frame.png"
        image = Image.new("RGB", (480, 800), "black")
        draw = ImageDraw.Draw(image)
        for name, color, bbox in TILE_EXPECTATIONS:
            box = list(bbox)
            if name == shift_name:
                box[0] += 3
                box[2] += 3
            draw.rectangle(box, fill=rgb(color))
            # Content holes do not prevent the surrounding surface from being tracked.
            draw.rectangle((box[0] + 30, box[1] + 30, box[0] + 45, box[1] + 45), fill="white")
        image.save(frame)
        manifest = root / "manifest.json"
        manifest.write_text(json.dumps({"resolution": [480, 800]}), encoding="utf-8")
        return frame, manifest

    def test_matching_geometry_passes_and_writes_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            native_root = root / "native"
            flutter_root = root / "flutter"
            native_root.mkdir()
            flutter_root.mkdir()
            native, _ = self.fixture(native_root)
            flutter, manifest = self.fixture(flutter_root)
            report = compare(native, flutter, manifest, root / "result")
            self.assertTrue(report["passed"])
            self.assertTrue((root / "result" / "report.json").exists())
            self.assertTrue((root / "result" / "side-by-side.png").exists())

    def test_shifted_tile_fails_after_preserving_report(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            native_root = root / "native"
            flutter_root = root / "flutter"
            native_root.mkdir()
            flutter_root.mkdir()
            native, _ = self.fixture(native_root)
            flutter, manifest = self.fixture(flutter_root, shift_name="calendar")
            with self.assertRaisesRegex(ValueError, "calendar"):
                compare(native, flutter, manifest, root / "result")
            report = json.loads((root / "result" / "report.json").read_text())
            self.assertFalse(report["passed"])


if __name__ == "__main__":
    unittest.main()
