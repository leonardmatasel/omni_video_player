import 'package:flutter/widgets.dart';

/// Lays [child] out at the size [fit] gives the video in the box, centred
/// and clipped: never scaled. An empty [size] falls back to 16:9.
class OmniVideoFit extends StatelessWidget {
  final Size size;
  final BoxFit fit;
  final Widget child;

  const OmniVideoFit({
    super.key,
    required this.size,
    required this.fit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final video = size.isEmpty ? const Size(16, 9) : size;
    return LayoutBuilder(
      builder: (context, box) {
        final fitted = applyBoxFit(fit, video, box.biggest);
        final childSize = fitted.source.isEmpty
            ? Size.zero
            : Size(
                video.width * fitted.destination.width / fitted.source.width,
                video.height * fitted.destination.height / fitted.source.height,
              );
        return ClipRect(
          child: OverflowBox(
            minWidth: childSize.width,
            maxWidth: childSize.width,
            minHeight: childSize.height,
            maxHeight: childSize.height,
            child: child,
          ),
        );
      },
    );
  }
}

/// [OmniVideoFit] for players without a controller (web iframes): shows
/// [child] at [startSize] at once, then refits when [videoSize] completes.
/// A failed [videoSize] keeps [startSize].
class OmniWebVideoFit extends StatefulWidget {
  final Size startSize;
  final Future<Size> Function() videoSize;
  final BoxFit fit;
  final Widget child;

  const OmniWebVideoFit({
    super.key,
    required this.startSize,
    required this.videoSize,
    required this.fit,
    required this.child,
  });

  @override
  State<OmniWebVideoFit> createState() => _OmniWebVideoFitState();
}

class _OmniWebVideoFitState extends State<OmniWebVideoFit> {
  late final Future<Size> _size = widget.videoSize().catchError(
    (Object _) => widget.startSize,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _size,
      initialData: widget.startSize,
      builder: (context, size) =>
          OmniVideoFit(size: size.data!, fit: widget.fit, child: widget.child),
    );
  }
}
