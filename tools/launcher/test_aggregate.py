import json,unittest,hashlib
from pathlib import Path
from PIL import Image
import aggregate
class AggregateTests(unittest.TestCase):
 def test_registry_has_every_plan_id_and_existing_refs(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text()); plan=json.loads((Path(__file__).with_name("scenarios.json")).read_text())
  self.assertEqual({x["id"] for x in plan["scenarios"]},{x["id"] for x in d["scenario_registry"]})
  for row in d["scenario_registry"]:
   for t in row["trials"]: self.assertTrue((aggregate.ROOT/t["reset_frame"]).exists())
 def test_v4_outcomes_geometry_and_phases(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text())
  self.assertEqual(4,d["schema_version"]); self.assertGreaterEqual(len(d["geometry"]["tile_icons"]),6)
  self.assertGreaterEqual(len(d["geometry"]["tile_labels_live_text"]),4); self.assertGreaterEqual(len(d["geometry"]["motion_phase_samples"]),15)
  self.assertEqual("snap-back/rejected commit",next(x for x in d["scenario_registry"] if x["id"]=="app_list_to_start_flick")["observed_outcome"])
  self.assertFalse("anomalies" in d); edit=d["geometry"]["edit_mode"]
  for key in ("unpin","resize"):
   box=edit[key]["bbox"]; center=edit[key]["center"]; self.assertTrue(0<=box[0]<=box[2]<480 and 0<=box[1]<=box[3]<800); self.assertTrue(box[0]<=center[0]<=box[2])
  for phase in d["geometry"]["motion_phase_samples"]:
   self.assertIn("numeric_observation",phase)
   for ref in phase["frames"]: self.assertTrue((aggregate.ROOT/ref).exists())
 def test_manifest_hashes_and_preview_note_source_bytes(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text())
  for row in d["scenario_registry"]:
   for t in row["trials"]:
    manifest=aggregate.ROOT/"runs/capture"/t["session"]/t["trial"] / "manifest.json"
    self.assertEqual(t["manifest_sha256"],hashlib.sha256(manifest.read_bytes()).hexdigest())
  root=aggregate.ROOT/"runs/capture/single-drag-cancel-confirmation-01/app_list_to_start_cancel_r03/frames"
  expected="4a976011212db2d29e2e58f2eeebef62136f95eaae29482e36ecd72ba31fef4d"
  for n in (0,35,53):
   p=root/f"{n:06d}.png"; self.assertEqual(expected,hashlib.sha256(p.read_bytes()).hexdigest())
   with Image.open(p) as im:
    self.assertEqual((480,800),im.size); self.assertEqual(33627,sum(max(px)>20 for px in im.convert("RGB").getdata()))
 def test_home_entry_uses_calculator_confirmation_and_rejects_old_precondition(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text())
  row=next(x for x in d["scenario_registry"] if x["id"]=="app_to_start_home")
  self.assertEqual(3,row["repeats"])
  self.assertEqual({"calculator-home-confirmation-01"},{t["session"] for t in row["trials"]})
  self.assertTrue(all(t["trial_gate_passed"] for t in row["trials"]))
  rejected=next(x for x in row["supplemental_evidence"] if isinstance(x,dict))
  self.assertEqual("invalid-precondition-app-list",rejected["reason"])
  self.assertFalse(rejected["requested_outcome_achieved"])
  phase=next(x for x in d["geometry"]["motion_phase_samples"] if x["interaction"]=="app_to_start_home")
  self.assertEqual([0,25,49],phase["numeric_observation"]["frame_indices"])
  self.assertIn("calculator-home-confirmation-01",phase["frames"][0])
 def test_alphabet_cancel_uses_settled_grid_trials_and_rejects_calculator_launches(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text())
  row=next(x for x in d["scenario_registry"] if x["id"]=="alphabet_grid_cancel")
  self.assertEqual(3,row["repeats"])
  self.assertEqual({"alphabet-cancel-corrected-01"},{t["session"] for t in row["trials"]})
  self.assertTrue(row["scenario_motion_claim_eligible"])
  rejected=next(x for x in row["supplemental_evidence"] if isinstance(x,dict))
  self.assertEqual("invalid-precondition-unsettled-app-list",rejected["reason"])
  self.assertFalse(rejected["requested_outcome_achieved"])
  self.assertIn("Calculator",rejected["observed_outcome"])
  phase=next(x for x in d["geometry"]["motion_phase_samples"] if x["interaction"]=="alphabet_grid_cancel")
  self.assertIn("alphabet-cancel-corrected-01",phase["frames"][0])
  plan=json.loads((Path(__file__).with_name("scenarios.json")).read_text())
  scenario=next(x for x in plan["scenarios"] if x["id"]=="alphabet_grid_cancel")
  self.assertEqual("wait",scenario["precondition_actions"][1]["op"])
  self.assertEqual(1.5,scenario["precondition_actions"][1]["seconds"])

 def test_alphabet_selection_uses_settled_b_cell_and_rejects_reversed_old_trials(self):
  aggregate.main(); d=json.loads(aggregate.OUT.read_text())
  row=next(x for x in d["scenario_registry"] if x["id"]=="alphabet_grid_select")
  self.assertEqual(3,row["repeats"])
  self.assertEqual({"alphabet-select-corrected-01"},{t["session"] for t in row["trials"]})
  self.assertIn("B section",row["observed_outcome"])
  self.assertFalse(row["scenario_motion_claim_eligible"])
  rejected=next(x for x in row["supplemental_evidence"] if isinstance(x,dict))
  self.assertEqual("invalid-precondition-and-invalid-terminal",rejected["reason"])
  self.assertFalse(rejected["requested_outcome_achieved"])
  phase=next(x for x in d["geometry"]["motion_phase_samples"] if x["interaction"]=="alphabet_grid_select")
  self.assertIn("alphabet-select-corrected-01",phase["frames"][0])
  self.assertEqual([0,11,28],phase["numeric_observation"]["frame_indices"])
  grid=d["geometry"]["alphabet_grid"]
  self.assertEqual([135,19,233,117],grid["cell_a_bbox"])
  self.assertEqual([246,19,344,117],grid["cell_b_bbox"])
  self.assertEqual([99,99],grid["cell_size_px"])
  self.assertEqual(12,grid["gutter_px"])
  plan=json.loads((Path(__file__).with_name("scenarios.json")).read_text())
  scenario=next(x for x in plan["scenarios"] if x["id"]=="alphabet_grid_select")
  self.assertEqual(["swipe","wait","tap","wait"],[x["op"] for x in scenario["precondition_actions"]])
  self.assertEqual({"x":295,"y":68},{k:scenario["actions"][0][k] for k in ("x","y")})
