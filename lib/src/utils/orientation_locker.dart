import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that locks the device's screen orientation to a specified orientation
/// while it is in the widget tree.
///
/// When inserted, this widget sets the preferred device orientations to either
/// portrait or landscape modes depending on the provided [orientation]. Upon disposal,
/// it restores the system's default orientation settings.
///
/// This is useful for scenarios like full-screen video playback or games
/// where a fixed orientation improves user experience.
///
/// Example:
/// ```dart
/// OrientationLocker(
///   orientation: Orientation.landscape,
///   child: YourVideoPlayer(),
/// )
/// ```
class OrientationLocker extends StatefulWidget {
  final Orientation orientation;
  final Widget child;

  const OrientationLocker({
    super.key,
    required this.orientation,
    required this.child,
  });

  @override
  State<OrientationLocker> createState() => _OrientationLockerState();
}

class _OrientationLockerState extends State<OrientationLocker> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      if (widget.orientation == Orientation.portrait) ...[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ] else ...[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]); // empty list mean system default
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
