import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';

/// A widget that displays a video player and adapts its aspect ratio
/// based on the video's rotation.
///
/// This widget ensures that the video is correctly displayed regardless
/// of its orientation (portrait or landscape) by adjusting the aspect ratio
/// dynamically according to the rotation angle.
///
/// The `rotationCorrection` value indicates the video's rotation angle in degrees:
/// - 90 or 270 means the video is in portrait orientation.
/// - 0 or 180 means the video is in landscape orientation.
///
/// The aspect ratio is calculated accordingly to maintain the correct
/// display proportions.
class AdaptiveVideoPlayerDisplay extends StatelessWidget {
  /// Controller that manages media playback and provides video properties.
  final OmniPlaybackController controller;

  final bool isFullScreenDisplay;

  const AdaptiveVideoPlayerDisplay({
    super.key,
    required this.controller,
    required this.isFullScreenDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = (controller.rotationCorrection == 90 ||
            controller.rotationCorrection == 270)
        ? controller.size.height / controller.size.width
        : controller.size.width / controller.size.height;

    return AnimatedBuilder(
      animation: Listenable.merge([
        controller,
        // ascolta isFullScreen o altri state update
        controller.sharedPlayerNotifier,
        // ascolta il cambiamento del widget video
      ]),
      builder: (context, _) {
        final player = controller.sharedPlayerNotifier.value;

        final shouldRender = isFullScreenDisplay == controller.isFullScreen;

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
            child: shouldRender
                ? (player ?? const SizedBox.shrink())
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
