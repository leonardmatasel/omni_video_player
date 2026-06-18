import 'package:flutter/widgets.dart';

/// Inherited flag that tells control surfaces (play/pause button, loader and
/// skip indicators, playlist prev/next buttons) to use an opaque background
/// instead of the default translucent one.
///
/// It is set to `true` for players rendered over a WebView that shows its own
/// native controls underneath — notably the YouTube IFrame player — so our
/// controls fully mask the native ones instead of letting them bleed through.
/// Defaults to `false` when no ancestor is present.
class OpaqueControlSurfaces extends InheritedWidget {
  const OpaqueControlSurfaces({
    super.key,
    required this.opaque,
    required super.child,
  });

  /// Whether control surfaces should be drawn fully opaque.
  final bool opaque;

  /// Returns the nearest [opaque] value, or `false` when there is no ancestor.
  static bool of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<OpaqueControlSurfaces>();
    return inherited?.opaque ?? false;
  }

  @override
  bool updateShouldNotify(OpaqueControlSurfaces oldWidget) =>
      opaque != oldWidget.opaque;
}
