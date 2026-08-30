import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from compare_primitives import SURFACES, compare


class ComparePrimitivesTest(unittest.TestCase):
    def _fixture(self, root: Path, surface: str, shift: int = 0):
        native = Image.new("RGB", (480, 800), "black")
        flutter = Image.new("RGB", (480, 800), "black")
        native_draw = ImageDraw.Draw(native)
        flutter_draw = ImageDraw.Draw(flutter)
        for item in SURFACES[surface]:
            native_draw.rectangle(item.bounds, fill=item.native_color)
            bounds = list(item.bounds)
            bounds[0] += shift
            bounds[2] += shift
            flutter_draw.rectangle(bounds, fill=item.flutter_color)
        native_path = root / "native.png"
        flutter_path = root / "flutter.png"
        manifest = root / "manifest.json"
        native.save(native_path)
        flutter.save(flutter_path)
        manifest.write_text(json.dumps({"resolution": [480, 800]}), encoding="utf-8")
        return native_path, flutter_path, manifest

    def test_app_list_passes_exact_fixture(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            paths = self._fixture(root, "app-list")
            report = compare("app-list", *paths, root / "out")
            self.assertTrue(report["passed"])

    def test_alphabet_supports_measured_palette_difference(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            paths = self._fixture(root, "alphabet")
            report = compare("alphabet", *paths, root / "out")
            self.assertTrue(report["passed"])

    def test_shifted_fixture_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            paths = self._fixture(root, "app-list", shift=3)
            with self.assertRaises(ValueError):
                compare("app-list", *paths, root / "out", tolerance_px=1)


if __name__ == "__main__":
    unittest.main()
