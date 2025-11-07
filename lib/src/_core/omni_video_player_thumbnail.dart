import 'package:flutter/material.dart';

/// A static, non-interactive image preview for a video player.
///
/// [VideoPlayerThumbnail] shows a thumbnail image using the provided
/// [ImageProvider]. It does not respond to playback state changes and is wrapped
/// in an [IgnorePointer], so it won’t handle any user interactions.
///
/// This widget is typically displayed before the video starts playing.
class VideoPlayerThumbnail extends StatelessWidget {
  /// Creates a thumbnail preview for the video player.
  const VideoPlayerThumbnail({
    super.key,
    required this.imageProvider,
    required this.fit,
    required this.backgroundColor,
  });

  /// The image to be displayed as a preview.
  final ImageProvider imageProvider;

  /// How to fit the image within its bounds.
  final BoxFit fit;

  /// Background color behind the thumbnail image.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: IgnorePointer(
        child: Image(image: imageProvider, fit: fit),
      ),
    );
  }
}
