"""Unit checks for failure-prone measurement logic; native data is verified separately."""
import unittest
import numpy as np
from analyze_native import marker_bounds, bar_left, header_match, match_input_clocks, require_comparable_timing, COLORS
from compare_motion import calibrate_bar, track_bar, sample_error


class MeasurementTests(unittest.TestCase):
    def test_buffered_callbacks_cannot_make_aligned_motion_claims(self):
        require_comparable_timing(dict(clock_alignment=dict(receipt_spread_ms=21)))
        with self.assertRaisesRegex(ValueError, 'Unqualified'):
            require_comparable_timing(dict(clock_alignment=dict(receipt_spread_ms=638)))

    def test_comparison_calibrates_legacy_padding_and_clipped_edge(self):
        image=np.zeros((800,480,3),dtype=np.uint8)
        image[134:140,16:464]=COLORS[0]
        geometry=calibrate_bar(image)
        self.assertEqual(geometry,dict(x=16,y=134,width=448))
        image[:]=0;image[134:140,:200]=COLORS[0]
        self.assertEqual(track_bar(image,geometry,COLORS[0]),-248)
        self.assertIsNone(track_bar(image,geometry,COLORS[1]))

    def test_missing_page_is_not_a_perfect_positional_match(self):
        errors,mismatch=sample_error([24,None,None,None],[None,24,None,None])
        self.assertEqual(errors,[])
        self.assertTrue(mismatch)
        errors,mismatch=sample_error([24,None,None,None],[30,450,None,None])
        self.assertEqual(errors,[6])
        self.assertTrue(mismatch)

    def test_fractional_edge_and_clipping(self):
        image=np.zeros((800,480,3),dtype=np.uint8)
        image[314:378,91:154]=COLORS[1] # 63 solid pixels + antialiased edges.
        self.assertEqual(marker_bounds(image,COLORS[1])['x'],91)
        self.assertTrue(marker_bounds(image,COLORS[1])['complete'])
        image[:]=0;image[314:378,:30]=COLORS[1]
        self.assertTrue(marker_bounds(image,COLORS[1])['left_censored'])
        self.assertFalse(marker_bounds(image,COLORS[1])['complete'])

    def test_bar_is_not_a_marker(self):
        image=np.zeros((800,480,3),dtype=np.uint8)
        image[165:171,24:456]=COLORS[0]
        self.assertIsNone(marker_bounds(image,COLORS[0]))
        self.assertEqual(bar_left(image,COLORS[0]),24)
        image[:]=0; image[165:171,:200]=COLORS[0]
        self.assertEqual(bar_left(image,COLORS[0]),-232)

    def test_header_tracking_ignores_uniform_brightness_change(self):
        rng=np.random.default_rng(2)
        template=rng.integers(0,200,(96,80)).astype(float)
        image=np.zeros((800,480,3),dtype=np.uint8)
        image[41:137,73:153]=np.repeat((template*.5).astype(np.uint8)[:,:,None],3,axis=2)
        x,score=header_match(image,template)
        self.assertEqual(x,73)
        self.assertGreater(score,.99)

    def test_clock_match_keeps_event_order_and_delay_spread(self):
        host=[dict(event='pointer',phase='down',x=20,y=30,host_received_ms=100),
              dict(event='pointer',phase='up',x=20,y=30,host_received_ms=200)]
        guest=[dict(event='Down',x='20',y='30',t_ms='810'),
               dict(event='Move',x='20',y='30',t_ms='895'),
               dict(event='Up',x='20',y='30',t_ms='900')]
        result=match_input_clocks(host,guest)
        self.assertEqual(result['matched_samples'],2)
        self.assertEqual(result['offset_ms'],705)
        self.assertEqual(result['receipt_spread_ms'],10)


if __name__=='__main__':unittest.main()
