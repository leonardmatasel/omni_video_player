import 'package:flutter/material.dart';

/// Renders [child] as the topmost entry of the Overlay that hosts the enclosing
/// route, instead of inside the route itself: a route only paints above the
/// route below it, so any OverlayEntry the app inserted above the route stack
/// (a player living in one, a banner, a PiP) would cover fullscreen.
/// The route stays on the stack and still owns pop and the back button.
class FullscreenOverlayHost extends StatefulWidget {
  const FullscreenOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  State<FullscreenOverlayHost> createState() => _FullscreenOverlayHostState();
}

class _FullscreenOverlayHostState extends State<FullscreenOverlayHost> {
  late final OverlayEntry _entry = OverlayEntry(builder: _buildOverlayChild);
  Animation<double>? _routeAnimation;
  bool _inserted = false;

  @override
  void initState() {
    super.initState();
    // Inserting while the route is building would dirty the Overlay mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Overlay.of(context).insert(_entry);
      _inserted = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The route's own transition now wraps an empty page, so the hoisted child
    // has to run it itself.
    _routeAnimation = ModalRoute.of(context)?.animation;
  }

  @override
  void didUpdateWidget(covariant FullscreenOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    if (_inserted) _entry.remove();
    super.dispose();
  }

  Widget _buildOverlayChild(BuildContext _) {
    final animation = _routeAnimation;
    return animation == null
        ? widget.child
        : FadeTransition(opacity: animation, child: widget.child);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
