import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

import 'component_gallery_shell.dart';

void main() => runApp(const ComponentGallery());

Widget _galleryAppBuilder(
  BuildContext context,
  Widget? child, {
  required bool disableAnimations,
}) {
  Widget wrapped = child ?? const SizedBox.shrink();
  if (disableAnimations) {
    wrapped = MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: wrapped,
    );
  }
  wrapped = DefaultTextStyle(
    style: wpPhoneDefaultTextStyle,
    child: wrapped,
  );
  // View.didChangeViewFocus (web "Enable accessibility") uses
  // ReadingOrderTraversalPolicy.findFirstFocus → FocusNode.rect → RenderBox.size.
  // Hub ListView rows below the fold are in the tree but not laid out.
  return FocusTraversalGroup(
    policy: WidgetOrderTraversalPolicy(),
    child: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              final focused = FocusManager.instance.primaryFocus?.context;
              Navigator.maybeOf(focused ?? context)?.maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: wrapped),
      ),
    ),
  );
}

/// Run with `flutter run -t lib/components.dart` from the example directory.
class ComponentGallery extends StatelessWidget {
  const ComponentGallery({super.key, this.disableAnimations = false});

  /// Test hook. Production relies on [MediaQuery.disableAnimationsOf].
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Windows Phone components',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => _galleryAppBuilder(
          context,
          child,
          disableAnimations: disableAnimations,
        ),
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: wpPivotFontFamily,
          colorScheme: const ColorScheme.dark(primary: Color(0xff1ba1e2)),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {}),
        ),
        initialRoute: Navigator.defaultRouteName,
        onGenerateRoute: (settings) => WpPhonePageRoute<void>(
          incomingMaxIndex: _galleryHomeFeatherMaxIndex,
          outgoingMaxIndex: _galleryHomeFeatherMaxIndex,
          settings: settings,
          builder: (_) => const GalleryHome(),
        ),
      );
}

/// Hub list rows use FeatheringIndex 2–5 (intro 2, three entries 3–5).
const _galleryHomeFeatherMaxIndex = 5;

class GalleryHome extends StatelessWidget {
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) => WpPhonePage(
        applicationTitle: 'windows phone',
        pageTitle: 'components',
        featherMaxIndex: _galleryHomeFeatherMaxIndex,
        featherBodyAsLayer: false,
        body: const _GalleryHomeBody(),
      );
}

class _GalleryHomeBody extends StatelessWidget {
  const _GalleryHomeBody();

  @override
  Widget build(BuildContext context) {
    final scope = WpPhoneFeatherScope.maybeOf(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        scope.featherLayer(
          key: const ValueKey('wp-phone-intro'),
          index: 2,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Experimental Flutter controls. Gallery list-to-detail uses '
                'Toolkit TurnstileFeather (RotationY, sequential out then in); '
                'clocks are source parameters, not a 21 fps curve fit.',
                style: TextStyle(
                  color: Color(0x99ffffff),
                  fontSize: 18,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
        WpPhoneListEntry(
          title: 'application bar',
          subtitle: 'Commands and overflow menu',
          featherIndex: 3,
          onPressed: () => pushWpPhonePage(
            context,
            const ApplicationBarDemo(),
            featherMaxIndex: WpTurnstileFeather.detailPageMaxIndex,
          ),
        ),
        WpPhoneListEntry(
          title: 'panorama',
          subtitle: 'Swipe through a wider canvas',
          featherIndex: 4,
          onPressed: () => pushWpPhonePage(
            context,
            const PanoramaDemo(),
            featherMaxIndex: 0,
          ),
        ),
        WpPhoneListEntry(
          title: 'toggle switch',
          subtitle: 'Tap, drag, or use the keyboard',
          featherIndex: 5,
          onPressed: () => pushWpPhonePage(
            context,
            const ToggleSwitchDemo(),
            featherMaxIndex: WpTurnstileFeather.detailPageMaxIndex,
          ),
        ),
      ],
    );
  }
}

class ApplicationBarDemo extends StatefulWidget {
  const ApplicationBarDemo({super.key});
  @override
  State<ApplicationBarDemo> createState() => _ApplicationBarDemoState();
}

class _ApplicationBarDemoState extends State<ApplicationBarDemo> {
  bool minimized = false;
  String message = 'Tap a command or open the menu.';

  void command(String name) => setState(() => message = '$name selected');

  @override
  Widget build(BuildContext context) => WpPhonePage(
        applicationTitle: 'components',
        pageTitle: 'application bar',
        applicationBar: WpApplicationBar(
          backgroundColor: const Color(0xff1f1f1f),
          mode: minimized
              ? WpApplicationBarMode.minimized
              : WpApplicationBarMode.defaultMode,
          actions: [
            WpApplicationBarAction(
                icon: const Icon(Icons.add),
                label: 'add',
                onPressed: () => command('add')),
            WpApplicationBarAction(
                icon: const Icon(Icons.refresh),
                label: 'refresh',
                onPressed: () => command('refresh')),
            const WpApplicationBarAction(
                icon: Icon(Icons.delete_outline), label: 'delete'),
          ],
          menuItems: [
            WpApplicationBarMenuItem(
                label: 'settings', onPressed: () => command('settings')),
            WpApplicationBarMenuItem(
                label: 'about', onPressed: () => command('about')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            Text(message,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                )),
            const SizedBox(height: 32),
            WpToggleSwitch(
              value: minimized,
              onChanged: (value) => setState(() => minimized = value),
              header: 'Minimized application bar',
            ),
            const SizedBox(height: 24),
            const Text(
                'The disabled command remains visible. Expansion timing is '
                'provisional; this screen is a functional demo, not a native replay.',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.none,
                )),
          ],
        ),
      );
}

class PanoramaDemo extends StatelessWidget {
  const PanoramaDemo({super.key});

  @override
  Widget build(BuildContext context) => const WpPhonePage(
        applicationTitle: 'components',
        pageTitle: 'panorama',
        showTitlePanel: false,
        body: WpPanorama(
          title: 'panorama',
          items: [
            WpPanoramaItem(
              header: 'first',
              child: _PanoramaSection(name: 'first', color: Color(0xff1ba1e2)),
            ),
            WpPanoramaItem(
              header: 'second',
              child: _PanoramaSection(name: 'second', color: Color(0xff60a917)),
            ),
            WpPanoramaItem(
              header: 'third',
              child: _PanoramaSection(name: 'third', color: Color(0xfff09609)),
            ),
          ],
        ),
      );
}

class _PanoramaSection extends StatelessWidget {
  const _PanoramaSection({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => ListView(children: [
        Container(height: 6, color: color),
        const SizedBox(height: 24),
        Text('$name page',
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              decoration: TextDecoration.none,
            )),
        const SizedBox(height: 12),
        const Text('Swipe to explore',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              decoration: TextDecoration.none,
            )),
        const SizedBox(height: 32),
        Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 64, height: 64, color: color)),
      ]);
}

class ToggleSwitchDemo extends StatefulWidget {
  const ToggleSwitchDemo({super.key});
  @override
  State<ToggleSwitchDemo> createState() => _ToggleSwitchDemoState();
}

class _ToggleSwitchDemoState extends State<ToggleSwitchDemo> {
  bool wifi = false;
  bool bluetooth = true;

  @override
  Widget build(BuildContext context) => WpPhonePage(
        applicationTitle: 'components',
        pageTitle: 'connections',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            WpToggleSwitch(
                value: wifi,
                header: 'Wi-Fi',
                onChanged: (value) => setState(() => wifi = value)),
            const SizedBox(height: 28),
            WpToggleSwitch(
                value: bluetooth,
                header: 'Bluetooth',
                onChanged: (value) => setState(() => bluetooth = value)),
            const SizedBox(height: 28),
            const WpToggleSwitch(
                value: true, header: 'Disabled', onChanged: null),
            const SizedBox(height: 40),
            const Text(
              'These switches change demo state only. They do not '
              'change your device connections.',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
}
