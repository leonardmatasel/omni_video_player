import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';

/// Opens [page] as the topmost entry of the Overlay that hosts the caller, with
/// an empty route behind it that keeps pop and the back button.
///
/// Not the route itself: a route only paints above the route below it, so any
/// OverlayEntry the app inserted over the route stack — a player living in one,
/// a banner, a PiP — would cover fullscreen.
///
/// The page grows from the inline player around [context] and shrinks back
/// into it; with no inline player on screen it fades. Completes once it is gone.
/// One thing at a time: growth, system UI (see [onFullscreenSettled]), controls,
/// and the other way round on exit.
///
/// [routeSettings] names that route, so a `NavigatorObserver` of the app can
/// tell it apart from a page of its own. [onShrink] runs as the page starts
/// shrinking back.
Future<void> openFullscreen(
  BuildContext context,
  WidgetBuilder page, {
  RouteSettings? routeSettings,
  VoidCallback? onShrink,
}) async {
  final route = _FullscreenRoute(routeSettings, onShrink);
  final inline = context
      .findAncestorStateOfType<State<OmniVideoPlayerControlsOverlay>>();
  final entry = OverlayEntry(
    // The page is mounted under the Overlay, not under the caller: the themes
    // around the caller, the player's own among them, have to come along.
    builder: (_) => _Growth(
      route: route,
      inline: inline,
      child: InheritedTheme.captureAll(context, page(context)),
    ),
  );
  // Insert now, not when the route builds: the shared player moves by
  // GlobalKey, and a frame's delay tears its webview down.
  Overlay.of(context).insert(entry);
  try {
    await Navigator.of(context).push(route);
  } finally {
    entry.remove();
  }
}

/// Whether the fullscreen page around [context] is not settled yet: growing,
/// waiting for the screen to turn, or on its way out.
bool isFullscreenMoving(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_Moving>()?.moving ?? false;

/// Lets the fullscreen page around [context] take the system UI once grown and
/// give it back before shrinking. Each returns the orientation it asked for:
/// the next step waits for the screen to turn, 500 ms at most.
void onFullscreenSettled(
  BuildContext context, {
  required Orientation? Function() enter,
  required Orientation? Function() exit,
}) {
  final growth = context.findAncestorStateOfType<_GrowthState>();
  growth?._enter = enter;
  growth?._exit = exit;
}

class _FullscreenRoute extends PageRouteBuilder<void> {
  _FullscreenRoute(RouteSettings? settings, this.onShrink)
    : super(
        settings: settings,
        pageBuilder: (_, _, _) => const SizedBox.shrink(),
      );

  // Not [animation]: the HeroController holds that one complete for the first
  // frame, and the page would flash full screen before growing.
  Animation<double> get growth => controller!.view;

  // Back and maybePop only ask: the route stays on top while the page shrinks,
  // so a second ask lands here again and not on the page below.
  @override
  RoutePopDisposition get popDisposition => RoutePopDisposition.doNotPop;

  VoidCallback? onLeave;

  @override
  void onPopInvokedWithResult(bool didPop, void result) {
    super.onPopInvokedWithResult(didPop, result);
    if (!didPop) onLeave?.call();
  }

  final VoidCallback? onShrink;

  Future<void> shrink() async {
    onShrink?.call();
    await controller!.reverse();
    if (isActive) navigator!.removeRoute(this);
  }
}

class _Moving extends InheritedWidget {
  const _Moving({required this.moving, required super.child});

  final bool moving;

  @override
  bool updateShouldNotify(_Moving oldWidget) => moving != oldWidget.moving;
}

class _Growth extends StatefulWidget {
  const _Growth({
    required this.route,
    required this.inline,
    required this.child,
  });

  final _FullscreenRoute route;
  final State? inline;
  final Widget child;

  @override
  State<_Growth> createState() => _GrowthState();
}

class _GrowthState extends State<_Growth> {
  late final _progress = CurvedAnimation(
    parent: widget.route.growth,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeOutCubic.flipped,
  );
  Orientation? Function()? _enter;
  Orientation? Function()? _exit;
  var _settled = false;
  var _leaving = false;

  late Orientation _orientation;
  Orientation? _turningTo;
  Completer<void>? _turned;

  @override
  void initState() {
    super.initState();
    widget.route.onLeave = _leave;
    _progress.addStatusListener(_onProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orientation = MediaQuery.orientationOf(context);
    final turned = _turned;
    if (_orientation == _turningTo && turned != null && !turned.isCompleted) {
      turned.complete();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _onProgress(AnimationStatus status) async {
    if (!status.isCompleted || _leaving) return;
    await _turn(_enter?.call());
    if (mounted && !_leaving) setState(() => _settled = true);
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() {
      _leaving = true;
      _settled = false;
    });
    await _turn(_exit?.call());
    if (widget.route.isActive) await widget.route.shrink();
  }

  /// Waits for the screen to turn to [orientation], 500 ms at most. On web
  /// nothing turns.
  Future<void> _turn(Orientation? orientation) {
    if (orientation == null || kIsWeb || orientation == _orientation) {
      return Future.value();
    }
    _turningTo = orientation;
    final turned = _turned = Completer();
    return turned.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {},
    );
  }

  /// The inline player's box as insets of the overlay, measured every frame
  /// so it follows the page; null when it is gone or off screen.
  RelativeRect? _inlinePlace() {
    final inline = widget.inline;
    final overlay = Overlay.of(context).context.findRenderObject();
    final box = inline != null && inline.mounted
        ? inline.context.findRenderObject()
        : null;
    if (overlay is! RenderBox || !overlay.hasSize) return null;
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (box.size.isEmpty) return null;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    if (!rect.overlaps(Offset.zero & overlay.size)) return null;
    return RelativeRect.fromSize(rect, overlay.size);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, page) {
        final t = _progress.value;
        final moving = !_settled;
        final from = _progress.isCompleted ? null : _inlinePlace();

        // One tree for growth and fade, or switching would remount the page.
        return AbsorbPointer(
          absorbing: moving,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: from == null ? 0 : t),
                ),
              ),
              Positioned.fromRelativeRect(
                rect: RelativeRect.lerp(from, RelativeRect.fill, t)!,
                child: Opacity(
                  opacity: from == null ? t : 1,
                  child: _Moving(moving: moving, child: page!),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
