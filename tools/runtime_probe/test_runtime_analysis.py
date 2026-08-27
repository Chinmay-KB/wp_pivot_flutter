import unittest
from analyze import animation_gaps, distribution


class RuntimeAnalysisTests(unittest.TestCase):
    def test_cadence_excludes_idle_but_retains_stalls(self):
        frames = [dict(vsyncStart=t) for t in
                  [0, 1000000, 1016000, 1200000, 1216000, 2200000, 2216000]]
        gaps = animation_gaps(frames, [dict(absolute_us=1000000)])
        self.assertEqual(gaps, [16, 184, 16])
        self.assertEqual(distribution(gaps)['over_60hz_budget'], 1)

    def test_missing_samples_are_not_zero_cost(self):
        result = distribution([])
        self.assertIsNone(result['p50_ms'])
        self.assertIsNone(result['max_ms'])
        self.assertEqual(result['count'], 0)


if __name__ == '__main__':
    unittest.main()
