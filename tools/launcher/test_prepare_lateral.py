import json
import tempfile
import unittest
from pathlib import Path

from prepare_lateral import prepare_trial


class PrepareLateralTest(unittest.TestCase):
    def test_rebases_without_interpolating_events(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            trial = root / "start_to_app_list_drag_commit_r01"
            trial.mkdir()
            (trial / "manifest.json").write_text(
                json.dumps(
                    {
                        "resolution": [480, 800],
                        "errors": [],
                        "scenario": {"id": "start_to_app_list_drag_commit"},
                    }
                ),
                encoding="utf-8",
            )
            lines = [
                {"host_received_ms": 40, "event": "pointer", "phase": "down", "x": 420, "y": 400},
                {"host_received_ms": 90, "event": "pointer", "phase": "move", "x": 300, "y": 400},
                {"host_received_ms": 140, "event": "pointer", "phase": "up", "x": 60, "y": 400},
            ]
            (trial / "events.jsonl").write_text(
                "\n".join(json.dumps(item) for item in lines), encoding="utf-8"
            )
            (trial / "frames.csv").write_text("frame,capture_start_ms,capture_end_ms\n", encoding="utf-8")
            replay_path = prepare_trial(trial, root / "out")
            replay = json.loads(replay_path.read_text(encoding="utf-8"))
            self.assertEqual([item["t_ms"] for item in replay["events"]], [500, 550, 600])
            self.assertEqual([item["event"] for item in replay["events"]], ["down", "move", "up"])
            self.assertEqual(replay["initial_surface"], 0)
            self.assertEqual(replay["expected_surface"], 1)


if __name__ == "__main__":
    unittest.main()
