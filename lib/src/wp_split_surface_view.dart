import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A generic two-surface horizontal view matching the Start/app-list spatial
/// relationship observed on Windows Phone.
///
/// The two children remain exactly one viewport apart while the user drags.
/// This widget intentionally owns only presentation and gesture mechanics;
/// callers own the meaning and state of each surface.
class WpSplitSurfaceView extends StatefulWidget {
  const WpSplitSurfaceView({
    super.key,
    required this.first,
    required this.second,
    this.controller,
    this.initialSurface = 0,
    this.onSurfaceChanged,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
  }) : assert(initialSurface == 0 || initialSurface == 1);

  /// The child at surface index 0.
  final Widget first;

  /// The child at surface index 1.
  final Widget second;

  /// An optional caller-owned controller.
  ///
  /// When omitted, the view owns a controller initialized to [initialSurface].
  final PageController? controller;

  /// The initial surface used by the internally owned controller.
  final int initialSurface;

  /// Called after a drag or programmatic change settles on a surface.
  final ValueChanged<int>? onSurfaceChanged;

  /// Optional page physics. The platform page physics are used by default.
  final ScrollPhysics? physics;

  final DragStartBehavior dragStartBehavior;
  final bool allowImplicitScrolling;

  @override
  State<WpSplitSurfaceView> createState() => _WpSplitSurfaceViewState();
}

class _WpSplitSurfaceViewState extends State<WpSplitSurfaceView> {
  PageController? _ownedController;

  PageController get _controller => widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    _createOwnedControllerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant WpSplitSurfaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    _ownedController?.dispose();
    _ownedController = null;
    _createOwnedControllerIfNeeded();
  }

  void _createOwnedControllerIfNeeded() {
    if (widget.controller == null) {
      _ownedController = PageController(initialPage: widget.initialSurface);
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: widget.physics,
      dragStartBehavior: widget.dragStartBehavior,
      allowImplicitScrolling: widget.allowImplicitScrolling,
      onPageChanged: widget.onSurfaceChanged,
      children: <Widget>[
        KeyedSubtree(
            key: const ValueKey<String>('wp-split-first'), child: widget.first),
        KeyedSubtree(
            key: const ValueKey<String>('wp-split-second'),
            child: widget.second),
      ],
    );
  }
}
