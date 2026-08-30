import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from compare_lateral import extract_native_offset


class CompareLateralTest(unittest.TestCase):
    def test_extracts_start_anchor_translation(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "frame.png"
            image = Image.new("RGB", (480, 800), "black")
            ImageDraw.Draw(image).rectangle((0, 56, 133, 265), fill=(62, 101, 255))
            image.save(path)
            offset, evidence = extract_native_offset(path)
            self.assertEqual(offset, -100)
            self.assertEqual(evidence["anchors"][0]["name"], "start-phone-right")

    def test_extracts_app_anchor_translation(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "frame.png"
            image = Image.new("RGB", (480, 800), "black")
            ImageDraw.Draw(image).rectangle((206, 131, 267, 192), fill=(62, 101, 255))
            image.save(path)
            offset, evidence = extract_native_offset(path)
            self.assertEqual(offset, -360)
            self.assertEqual(evidence["anchors"][0]["name"], "app-alarm-left")


if __name__ == "__main__":
    unittest.main()
