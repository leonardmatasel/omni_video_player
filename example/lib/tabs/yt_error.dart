import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class YTError extends StatelessWidget {
  const YTError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OmniVideoPlayer(
        callbacks: VideoPlayerCallbacks(
          onControllerCreated: (controller) {
            // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
          },
        ),
        options: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.youtube(
            videoUrl: Uri.parse('https://www.youtube.com/watch?v=ysz5S6PUM-U'),
          ),
          playerTheme: OmniVideoPlayerThemeData().copyWith(
            colors: VideoPlayerColorScheme().copyWith(
              backgroundError: Colors.amber,
            ),
          ),
        ),
      ),
    );
  }
}
