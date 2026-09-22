import 'package:flutter/material.dart';

/// Opens [page] as the topmost entry of the Overlay that hosts the caller, with
/// an empty route behind it that keeps pop and the back button.
///
/// Not the route itself: a route only paints above the route below it, so any
/// OverlayEntry the app inserted over the route stack — a player living in one,
/// a banner, a PiP — would cover fullscreen.
///
/// [routeSettings] names that route, so a `NavigatorObserver` of the app can
/// tell it apart from a page of its own.
Future<void> openFullscreen(
  BuildContext context,
  WidgetBuilder page, {
  RouteSettings? routeSettings,
}) async {
  final route = PageRouteBuilder<void>(
    settings: routeSettings,
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
  final entry = OverlayEntry(
    builder: (_) {
      // The page is mounted under the Overlay, not under the caller: the themes
      // around the caller, the player's own among them, have to come along.
      final child = InheritedTheme.captureAll(context, page(context));
      final animation = route.animation;

      return animation == null
          ? child
          : FadeTransition(opacity: animation, child: child);
    },
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
