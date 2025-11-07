import 'package:flutter/material.dart';

class YoutubePlayerWidget extends StatelessWidget {
  final String videoId;
  final bool autoPlay;
  final bool mute;
  final int start;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.autoPlay,
    required this.mute,
    required this.start,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}
