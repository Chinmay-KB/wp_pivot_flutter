import json
import tempfile
import unittest
from pathlib import Path

import capture


def valid_plan():
    return {
        "schema_version": 1,
        "adapter_id": capture.ADAPTER_ID,
        "reference_viewport": [480, 800],
        "reset_settle_seconds": 1.5,
        "pre_roll_seconds": 0.5,
        "post_roll_seconds": 1.5,
        "scenarios": [
            {"id": "rest", "initial_state": "start-rest", "actions": []},
            {"id": "tap", "requires_visual_coordinate_check": True,
             "coordinate_verified": True,
             "initial_state": "start-rest",
             "coordinate_evidence": "verified clean frame retained with trial",
             "actions": [{"op": "tap", "x": 12, "y": 34}]},
        ],
    }


class PlanTests(unittest.TestCase):
    def test_selects_requested_scenario(self):
        _, selected = capture.validate_plan(valid_plan(), ["tap"])
        self.assertEqual(["tap"], [item["id"] for item in selected])

    def test_rejects_unknown_scenario(self):
        with self.assertRaisesRegex(capture.PlanError, "unknown scenario"):
            capture.validate_plan(valid_plan(), ["missing"])

    def test_rejects_unsafe_key(self):
        plan = valid_plan()
        plan["scenarios"][0]["actions"] = [{"op": "key", "name": "power"}]
        with self.assertRaisesRegex(capture.PlanError, "only Home and Back"):
            capture.validate_plan(plan)

    def test_rejects_out_of_bounds_coordinate(self):
        plan = valid_plan()
        plan["scenarios"][1]["actions"][0]["x"] = 480
        with self.assertRaisesRegex(capture.PlanError, "inside"):
            capture.validate_plan(plan)

    def test_rejects_unverified_coordinate_scenario(self):
        plan = valid_plan()
        plan["scenarios"][1]["coordinate_verified"] = False
        with self.assertRaisesRegex(capture.PlanError, "need visual verification"):
            capture.validate_plan(plan, ["tap"])

    def test_rejects_coordinate_action_without_evidence(self):
        plan = valid_plan()
        plan["scenarios"][1].pop("coordinate_evidence")
        with self.assertRaisesRegex(capture.PlanError, "coordinate_evidence"):
            capture.validate_plan(plan, ["tap"])

    def test_rejects_unknown_initial_state(self):
        plan = valid_plan()
        plan["scenarios"][0]["initial_state"] = "mystery"
        with self.assertRaisesRegex(capture.PlanError, "initial_state"):
            capture.validate_plan(plan)

    def test_replacement_alphabet_select_plan_waits_and_targets_declared_b_cell(self):
        plan = json.loads((Path(__file__).with_name("scenarios.json")).read_text(encoding="utf-8"))
        _, selected = capture.validate_plan(plan, ["alphabet_grid_select"])
        scenario = selected[0]
        self.assertEqual(["swipe", "wait", "tap", "wait"], [item["op"] for item in scenario["precondition_actions"]])
        self.assertEqual({"x": 295, "y": 68}, {key: scenario["actions"][0][key] for key in ("x", "y")})


class OutputTests(unittest.TestCase):
    def test_creates_fresh_output(self):
        with tempfile.TemporaryDirectory() as root:
            output = Path(root) / "new"
            capture.prepare_output(output)
            self.assertTrue(output.is_dir())

    def test_rejects_existing_output_without_modifying_it(self):
        with tempfile.TemporaryDirectory() as root:
            output = Path(root) / "existing"
            output.mkdir()
            marker = output / "marker.json"
            marker.write_text(json.dumps({"keep": True}), encoding="utf-8")
            with self.assertRaises(FileExistsError):
                capture.prepare_output(output)
            self.assertEqual({"keep": True}, json.loads(marker.read_text(encoding="utf-8")))


if __name__ == "__main__":
    unittest.main()
