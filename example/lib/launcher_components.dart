import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

void main() => runApp(const LauncherComponentsExample());

/// A composition example only: it contains no Android home role, app discovery,
/// intent launching, pin persistence, ordering, or live-data scheduling.
class LauncherComponentsExample extends StatelessWidget {
  const LauncherComponentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const WpPhoneTheme(
        data: WpPhoneThemeData.dark(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              width: 480,
              child: WpSplitSurfaceView(
                first: _StartSurface(),
                second: _AppSurface(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartSurface extends StatefulWidget {
  const _StartSurface();

  @override
  State<_StartSurface> createState() => _StartSurfaceState();
}

class _StartSurfaceState extends State<_StartSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _editingCalendar = false;

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  Future<void> _previewLaunch() async {
    if (_scene.isAnimating) return;
    await _scene.forward(from: 0);
    if (mounted) await _scene.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final specs = <_TileSpec>[
      const _TileSpec('Phone', 0, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec('Messages', 0, 2),
      const _TileSpec('Browser', 0, 3),
      const _TileSpec('Mail', 1, 2),
      const _TileSpec('Store', 1, 3),
      const _TileSpec('People', 2, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec('Music', 2, 2, color: Color(0xff107c10)),
      const _TileSpec('Games', 2, 3, color: Color(0xff107c10)),
      const _TileSpec('Office', 3, 2, color: Color(0xffeb3c00)),
      const _TileSpec('Notes', 3, 3, color: Color(0xff80397b)),
      const _TileSpec('Calendar', 4, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec("Kid's Corner", 4, 2, rowSpan: 2, columnSpan: 2),
    ];
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: WpTileGrid(
          placements: <WpTilePlacement>[
            for (final spec in specs)
              WpTilePlacement(
                row: spec.row,
                column: spec.column,
                rowSpan: spec.rowSpan,
                columnSpan: spec.columnSpan,
                child: WpStaggeredSceneTransition(
                  animation: _scene,
                  order: _startExitOrder(spec),
                  maxOrder: 4,
                  entryOrder: _startEntryOrder(spec),
                  maxEntryOrder: 5,
                  alignment: Alignment.centerLeft,
                  child: WpTile(
                    label: spec.label,
                    semanticLabel: spec.label,
                    color: spec.color,
                    editing: spec.label == 'Calendar' && _editingCalendar,
                    onTap: _previewLaunch,
                    onLongPress: spec.label == 'Calendar'
                        ? () => setState(() => _editingCalendar = true)
                        : null,
                    onUnpin: spec.label == 'Calendar'
                        ? () => setState(() => _editingCalendar = false)
                        : null,
                    onResize: spec.label == 'Calendar'
                        ? () => setState(() => _editingCalendar = false)
                        : null,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Start-grid sequencing belongs to this composition, not the transition.
double _startExitOrder(_TileSpec spec) =>
    4 - spec.column - spec.columnSpan + spec.row * 0.5;

double _startEntryOrder(_TileSpec spec) =>
    spec.column + spec.columnSpan - 1 + spec.row * 0.5;

class _AppSurface extends StatefulWidget {
  const _AppSurface();

  @override
  State<_AppSurface> createState() => _AppSurfaceState();
}

class _AppSurfaceState extends State<_AppSurface> {
  bool _alphabetOpen = false;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, IconData icon) => WpAppListRow(
          icon: Icon(icon),
          label: label,
          onTap: () {},
        );
    Widget header(String letter) => WpAppListHeader(
          letter: letter,
          onTap: () => setState(() => _alphabetOpen = true),
        );
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          WpAppListView(
            leadingAction: const Icon(Icons.search, color: Colors.white),
            children: <Widget>[
              header('a'),
              row('Alarms', Icons.alarm),
              header('b'),
              row('Battery Saver', Icons.battery_5_bar),
              header('c'),
              row('Calculator', Icons.calculate),
              row('Calendar', Icons.calendar_month),
              row('Camera', Icons.camera_alt),
              row('Cortana', Icons.circle_outlined),
              header('d'),
            ],
          ),
          if (_alphabetOpen)
            ColoredBox(
              color: Colors.black,
              child: WpAlphabetGrid(
                letters: List<String>.generate(
                  26,
                  (index) => String.fromCharCode(97 + index),
                ),
                enabledLetters: const <String>{'a', 'b', 'c'},
                onSelected: (_) => setState(() => _alphabetOpen = false),
                onCancel: () => setState(() => _alphabetOpen = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _TileSpec {
  const _TileSpec(
    this.label,
    this.row,
    this.column, {
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.color = const Color(0xff3e65ff),
  });

  final String label;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
  final Color color;
}
