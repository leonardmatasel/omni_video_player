import 'package:flutter/material.dart';

class VimeoVideoPlayer extends StatelessWidget {
  final String videoId;
  final bool autoPlay;
  final bool mute;

  const VimeoVideoPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.mute = false,
  });

  @override
  Widget build(BuildContext context) {
    // Questo non verrà MAI chiamato grazie al tuo if (kIsWeb),
    // ma serve a far felice il compilatore!
    return const SizedBox.shrink();
  }
}
