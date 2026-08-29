// Opt-in release-web measurement entrypoint. Never imported by the normal demo.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui' show FramePhase, FrameTiming;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'main.dart' show ResearchPivot;

@JS('performance.now')
external double _now();
@JS('pivotRuntimeReady')
external void _ready(JSFunction start);
@JS('pivotRuntimeReport')
external void _report(JSString json);

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme:
        ThemeData(brightness: Brightness.dark, fontFamily: wpPivotFontFamily),
    home: const RuntimeProbe()));

class RuntimeProbe extends StatefulWidget {
  const RuntimeProbe({super.key});
  @override
  State<RuntimeProbe> createState() => _RuntimeProbeState();
}

class _RuntimeProbeState extends State<RuntimeProbe> {
  final _surface = GlobalKey();
  Key _trialKey = UniqueKey();
  final _frames = <FrameTiming>[];
  final _trials = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _selections = [];
  bool _running = false;
  int _pointer = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready((() {
        _run();
      }).toJS);
    });
  }

  void _timings(List<FrameTiming> timings) => _frames.addAll(timings);

  Future<void> _until(double deadlineMs) async {
    while (_now() < deadlineMs) {
      final remaining = ((deadlineMs - _now()) * 1000).ceil();
      if (remaining > 0) {
        await Future<void>.delayed(Duration(microseconds: remaining));
      }
    }
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    _frames.clear();
    _trials.clear();
    final started = DateTime.now().toUtc().toIso8601String();
    String? failure;
    SchedulerBinding.instance.addTimingsCallback(_timings);
    try {
      final cases =
          jsonDecode(await rootBundle.loadString('assets/runtime_replays.json'))
              as List;
      // One warm-up per scenario, then three measured repetitions. No artificial
      // frame pumping during each gesture/animation: real browser scheduling.
      for (var repetition = 0; repetition < 4; repetition++) {
        for (final scenario in cases) {
          setState(() {
            _trialKey = UniqueKey();
          });
          await SchedulerBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 400));
          _selections = [];
          final surface =
              _surface.currentContext!.findRenderObject()! as RenderBox;
          final viewId = View.of(_surface.currentContext!).viewId;
          final scale = surface.size.width / 480;
          final events = scenario['replay']['events'] as List;
          final firstTime = (events.first['t_ms'] as num).toDouble();
          final start = _now();
          final delivered = <Map<String, dynamic>>[];
          Offset previous = Offset.zero;
          for (final event in events) {
            final planned = (event['t_ms'] as num).toDouble() - firstTime;
            await _until(start + planned);
            final point = surface.localToGlobal(Offset(
                (event['x'] as num).toDouble() * scale,
                (event['y'] as num).toDouble() * scale));
            final actual = _now();
            final stamp = Duration(microseconds: (actual * 1000).round());
            final PointerEvent input;
            switch (event['event']) {
              case 'down':
                _pointer++;
                input = PointerDownEvent(
                    viewId: viewId,
                    pointer: _pointer,
                    position: point,
                    timeStamp: stamp);
              case 'move':
                input = PointerMoveEvent(
                    viewId: viewId,
                    pointer: _pointer,
                    position: point,
                    delta: point - previous,
                    timeStamp: stamp);
              case 'up':
                input = PointerUpEvent(
                    viewId: viewId,
                    pointer: _pointer,
                    position: point,
                    timeStamp: stamp);
              default:
                throw StateError('Unknown input phase');
            }
            WidgetsBinding.instance.handlePointerEvent(input);
            previous = point;
            delivered.add({
              'event': event['event'],
              'planned_ms': planned,
              'actual_ms': actual - start,
              'absolute_us': (actual * 1000).round(),
              'x': event['x'],
              'y': event['y']
            });
          }
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          _trials.add({
            'scenario': scenario['id'],
            'repetition': repetition,
            'warmup': repetition == 0,
            'start_us': (start * 1000).round(),
            'end_us': (_now() * 1000).round(),
            'inputs': delivered,
            'selections': _selections,
            'expected_selections': [
              for (final e in scenario['replay']['selection_events'] as List)
                e['index']
            ],
            'replay_sha256': scenario['sha256']
          });
        }
      }
      // Web batches timing reports. Request only post-trial frames to flush them;
      // these are outside every trial window and excluded from analysis.
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        SchedulerBinding.instance.scheduleFrame();
        await SchedulerBinding.instance.endOfFrame;
      }
    } catch (error, stack) {
      failure = '$error\n$stack';
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(_timings);
      _running = false;
    }
    if (!mounted) return;
    final view = View.of(context);
    _report(jsonEncode({
      'schema_version': 1,
      'started_utc': started,
      'failure': failure,
      'mode': 'Flutter release web / real wall-clock replay',
      'input_source':
          'app-injected recorded touch paths; not physical touch latency',
      'clock':
          'performance.now; same origin as this Flutter web engine FrameTiming',
      'limits': 'Raster finish is engine submission, not display presentation. '
          'Warm-up trials excluded from aggregate. No mobile/native Windows claim.',
      'viewport': [360, 600],
      'device_pixel_ratio': view.devicePixelRatio,
      'host_view_physical_size': [
        view.physicalSize.width,
        view.physicalSize.height
      ],
      'trials': _trials,
      'frames': [
        for (final f in _frames)
          {
            'number': f.frameNumber,
            for (final phase in FramePhase.values)
              phase.name: f.timestampInMicroseconds(phase),
            'build_us': f.buildDuration.inMicroseconds,
            'raster_us': f.rasterDuration.inMicroseconds,
            'total_us': f.totalSpan.inMicroseconds,
          }
      ]
    }).toJS);
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Colors.black,
      child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 48),
              child: SizedBox(
                  key: _surface,
                  width: 360,
                  height: 600,
                  child: ResearchPivot(
                      key: _trialKey,
                      onChanged: (index) {
                        _selections.add({
                          'index': index,
                          'absolute_us': (_now() * 1000).round()
                        });
                      })))));
}
