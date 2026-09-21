import 'package:flutter/material.dart';

/// Opens [page] fullscreen. A player in an OverlayEntry above the route stack
/// would be covered by that entry, so there the page gets an entry on top and
/// an empty route behind it keeps pop and the back button.
Future<void> openFullscreen(BuildContext context, WidgetBuilder page) {
  return ModalRoute.of(context) == null
      ? _openAboveOverlay(context, page)
      : Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => page(context),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
}

Future<void> _openAboveOverlay(BuildContext context, WidgetBuilder page) async {
  final route = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
  final entry = OverlayEntry(
    builder: (_) {
      final child = page(context);
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
