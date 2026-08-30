import csv, hashlib, json, tempfile, unittest
from pathlib import Path
from PIL import Image
import analyze

class AnalysisTests(unittest.TestCase):
    def trial(self, root, name="start_rest_r01", corrupt=False, manifest_errors=None):
        trial = Path(root) / name; (trial / "frames").mkdir(parents=True)
        rows=[]
        for i in range(2):
            p=trial/"frames"/f"{i:06d}.png"; Image.new("RGB",(480,800),(62,101,255)).save(p)
            digest=hashlib.sha256(p.read_bytes()).hexdigest(); rows.append({"frame":i,"capture_start_ms":i*80,"capture_end_ms":i*80+1,"sha256":"bad" if corrupt and i==1 else digest,"bytes":p.stat().st_size})
        with (trial/"frames.csv").open("w",newline="") as f:
            w=csv.DictWriter(f,fieldnames=rows[0]); w.writeheader();w.writerows(rows)
        (trial/"events.jsonl").write_text("",encoding="utf-8")
        (trial/"manifest.json").write_text(json.dumps({"resolution":[480,800],"errors":manifest_errors or [],"scenario":{"id":"start_rest"}}),encoding="utf-8")
        return trial
    def test_corrupt_frame_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            data=analyze.load_trial(self.trial(d,corrupt=True)); self.assertFalse(data["quality"]["hashes_valid"])
    def test_fresh_output_enforced(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); self.trial(root); output=root/"out"; output.mkdir()
            with self.assertRaises(FileExistsError): analyze.analyze(root,output)

    def test_manifest_error_blocks_trial_gate_even_when_frames_are_valid(self):
        with tempfile.TemporaryDirectory() as d:
            trial = self.trial(d, manifest_errors=["invalid-precondition"])
            # Two frames deliberately leave the timing/change gate false; edit
            # the fixture to make every non-error condition true.
            rows = list(csv.DictReader((trial / "frames.csv").open()))
            for index in range(2, 7):
                p = trial / "frames" / f"{index:06d}.png"
                Image.new("RGB", (480, 800), (index, 101, 255)).save(p)
                rows.append({"frame": index, "capture_start_ms": index * 80,
                             "capture_end_ms": index * 80 + 1,
                             "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                             "bytes": p.stat().st_size})
            with (trial / "frames.csv").open("w", newline="") as file:
                writer = csv.DictWriter(file, fieldnames=rows[0]); writer.writeheader(); writer.writerows(rows)
            quality = analyze.load_trial(trial)["quality"]
            self.assertTrue(quality["hashes_valid"])
            self.assertEqual(5, quality["changed_observations"])
            self.assertFalse(quality["trial_gate_passed"])
