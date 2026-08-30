import hashlib,json,unittest
from pathlib import Path
import media_index
class MediaIndexTests(unittest.TestCase):
 def test_every_media_directory_is_indexed(self):
  media_index.main();d=json.loads((media_index.ROOT/'media-index.json').read_text());self.assertEqual({x.name for x in media_index.ROOT.iterdir() if x.is_dir()},{x['slug'] for x in d['items']});self.assertEqual(media_index.CANON,{x['slug'] for x in d['items'] if x['kind']=='canonical'})
 def test_corrected_start_entry_has_calculator_and_entry_phase_provenance(self):
  media_index.main(); index=json.loads((media_index.ROOT/'media-index.json').read_text())
  item=next(x for x in index['items'] if x['slug']=='start-entry')
  self.assertEqual('app_to_start_home_r03',item['source_trial'])
  self.assertEqual('calculator-home-confirmation-01',item['poster_source']['source_session'])
  self.assertEqual(25,item['poster_source']['frame'])
  self.assertEqual('Start tiles entering in staggered 3D',item['poster_source']['selection_rationale'])
  self.assertEqual('Calculator keypad surface',item['visual_check']['first']['observed_state'])
  self.assertEqual('Start tiles entering in staggered 3D',item['visual_check']['middle']['observed_state'])
  self.assertEqual('settled Start tile grid',item['visual_check']['last']['observed_state'])
 def test_corrected_alphabet_cancel_uses_grid_dismissal_not_old_calculator_launch(self):
  media_index.main(); index=json.loads((media_index.ROOT/'media-index.json').read_text())
  item=next(x for x in index['items'] if x['slug']=='alphabet-cancel')
  self.assertEqual('alphabet_grid_cancel_r03',item['source_trial'])
  self.assertEqual('alphabet-cancel-corrected-01',item['poster_source']['source_session'])
  self.assertEqual(18,item['poster_source']['frame'])
  self.assertEqual('alphabet grid folding away over the returning app list',item['visual_check']['middle']['observed_state'])
  self.assertEqual('app-list A-through-D rows restored after Back',item['visual_check']['last']['observed_state'])
 def test_all_canonical_visual_checks_and_posters_resolve_to_mapped_raw_bytes(self):
  media_index.main(); index=json.loads((media_index.ROOT/'media-index.json').read_text())
  banned=('native initial state','interaction phase','recorded outcome','mapped raw frame')
  canonical=[item for item in index['items'] if item['kind']=='canonical']
  self.assertEqual(media_index.CANON,{item['slug'] for item in canonical})
  for item in canonical:
   directory=media_index.ROOT/item['slug']; manifest=json.loads((directory/'media-manifest.json').read_text())
   trial=media_index.source_trial(manifest,item['slug']); check=item['visual_check']
   self.assertEqual({'first','middle','last'},set(check))
   for phase,entry in check.items():
    self.assertTrue(entry['passed'],f"{item['slug']} {phase}")
    self.assertTrue(entry['expected_state'].strip()); self.assertTrue(entry['observed_state'].strip())
    self.assertFalse(any(word in entry['observed_state'].lower() for word in banned))
    raw=media_index.STUDY/entry['raw_relative_path']; self.assertTrue(raw.exists())
    self.assertEqual(entry['source_sha256'],hashlib.sha256(raw.read_bytes()).hexdigest())
    self.assertIn({'source_frame':entry['raw_source_frame'],'source_sha256':entry['source_sha256']},[{k:v for k,v in source.items() if k in {'source_frame','source_sha256'}} for source in manifest['frame_map']])
   source=manifest['poster_source']; middle=check['middle']
   self.assertEqual(middle['raw_source_frame'],source['frame'])
   self.assertEqual(middle['source_sha256'],source['source_sha256'])
   poster=directory/'poster.png'; raw=media_index.STUDY/middle['raw_relative_path']
   self.assertEqual(hashlib.sha256(raw.read_bytes()).hexdigest(),hashlib.sha256(poster.read_bytes()).hexdigest())
   self.assertEqual(raw.read_bytes(),poster.read_bytes())
   self.assertEqual(manifest['files']['poster.png'],hashlib.sha256(poster.read_bytes()).hexdigest())

 def test_alphabet_select_requires_replacement_settle_b_cell_and_distinct_terminal(self):
  media_index.main(); index=json.loads((media_index.ROOT/'media-index.json').read_text())
  item=next(x for x in index['items'] if x['slug']=='alphabet-select')
  self.assertEqual('alphabet_grid_select_r03',item['source_trial'])
  self.assertEqual('alphabet-select-corrected-01',item['poster_source']['source_session'])
  self.assertEqual(11,item['poster_source']['frame'])
  self.assertIn('b cell occupies inclusive bounds [246,19,344,117]',item['visual_check']['first']['observed_state'])
  self.assertIn('Battery Saver, Calculator, Calendar, Camera, and Cortana',item['visual_check']['last']['observed_state'])
  manifest=json.loads((media_index.ROOT/'alphabet-select'/'media-manifest.json').read_text())
  trial=media_index.source_trial(manifest,'alphabet-select')
  media_index.validate_alphabet_select_evidence(trial,manifest)
  old=media_index.STUDY/'runs/capture/app-list-confirmation-01/alphabet_grid_select_r03'
  with self.assertRaisesRegex(RuntimeError,'replacement corrected session'):
   media_index.validate_alphabet_select_evidence(old,manifest)
