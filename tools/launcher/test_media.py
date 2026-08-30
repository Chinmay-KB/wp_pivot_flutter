import csv, hashlib, tempfile, unittest
from pathlib import Path
from PIL import Image
import media

class MediaTests(unittest.TestCase):
    def test_make_decode_and_fresh_output(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); trial=root/"trial"; (trial/"frames").mkdir(parents=True); rows=[]
            for i in range(2):
                p=trial/"frames"/f"{i:06d}.png"; Image.new("RGB",(480,800),(i*20,0,0)).save(p); rows.append({"frame":i,"capture_start_ms":i*80,"sha256":hashlib.sha256(p.read_bytes()).hexdigest()})
            with (trial/"frames.csv").open("w",newline="") as f: w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
            output=root/"out"; media.make(trial,output); self.assertTrue(media.verify(output)["ok"])
            with self.assertRaises(FileExistsError): media.make(trial,output)
