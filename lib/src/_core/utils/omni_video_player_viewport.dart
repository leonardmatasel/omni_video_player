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
class OmniVideoPlayerViewport extends StatelessWidget {
  /// Controller that manages media playback and provides video properties.
  final OmniPlaybackController controller;

  final bool isFullScreenDisplay;

  final double aspectRatio;

  const OmniVideoPlayerViewport({
    super.key,
    required this.controller,
    required this.isFullScreenDisplay,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller,
        controller.sharedPlayerNotifier,
      ]),
      builder: (context, _) {
        final player = controller.sharedPlayerNotifier.value != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: controller.sharedPlayerNotifier.value!,
                  ),
                  Positioned.fill(child: Container(color: Colors.transparent)),
                ],
              )
            : null;

        final shouldRender = isFullScreenDisplay == controller.isFullScreen;

        return AspectRatio(
          aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
          child: shouldRender
              ? (player ?? const SizedBox.shrink())
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
