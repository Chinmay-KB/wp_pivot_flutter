import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('component_capture', Path(__file__).with_name('capture.py'))
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class PlanTests(unittest.TestCase):
    def setUp(self):
        self.plan = {'product_id': 'C895C055-B418-4C72-AB3F-07BC05EEC201', 'control': 'native test',
                     'pre_roll_seconds': .5, 'post_roll_seconds': .8,
                     'scenarios': [{'id': 'tap', 'actions': [{'op': 'tap', 'x': 20, 'y': 30}]}]}

    def test_valid_plan(self):
        self.assertIs(capture.validate_plan(self.plan), self.plan)

    def test_unsafe_or_duplicate_ids(self):
        for name in ('../escape', '', 'a/b', 'c:\\path'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['scenarios'][0]['id'] = name
                capture.validate_plan(plan)
        self.plan['scenarios'] *= 2
        with self.assertRaises(ValueError):
            capture.validate_plan(self.plan)

    def test_invalid_values(self):
        for value in (True, float('nan'), float('inf'), -1, 11):
            with self.subTest(value=value), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['pre_roll_seconds'] = value
                capture.validate_plan(plan)

    def test_outside_viewport(self):
        self.plan['scenarios'][0]['actions'][0]['x'] = 480
        with self.assertRaises(ValueError):
            capture.validate_plan(self.plan)

    def test_reference_viewport_allows_other_logical_sizes(self):
        self.plan['reference_viewport'] = [768, 1280]
        self.plan['scenarios'][0]['actions'][0] = {'op': 'tap', 'x': 500, 'y': 900}
        self.assertIs(capture.validate_plan(self.plan), self.plan)
        self.plan['scenarios'][0]['actions'][0]['x'] = 768
        with self.assertRaises(ValueError):
            capture.validate_plan(self.plan)

    def test_unknown_action(self):
        self.plan['scenarios'][0]['actions'][0]['op'] = 'install'
        with self.assertRaises(ValueError):
            capture.validate_plan(self.plan)

    def test_hold_is_bounded_and_uses_one_point(self):
        self.plan['scenarios'][0]['actions'][0] = {
            'op': 'hold',
            'x': 220,
            'y': 360,
            'ms': 600,
        }
        self.assertIs(capture.validate_plan(self.plan), self.plan)
        for duration in (19, 5001, 200.5, True):
            with self.subTest(duration=duration), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['scenarios'][0]['actions'][0]['ms'] = duration
                capture.validate_plan(plan)

    def test_cleanup_validated(self):
        self.plan['scenarios'][0]['cleanup_actions'] = [{'op': 'key', 'name': 'start'}]
        with self.assertRaises(ValueError):
            capture.validate_plan(self.plan)


if __name__ == '__main__':
    unittest.main()
