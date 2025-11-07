import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class NetworkLink extends StatelessWidget {
  const NetworkLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.network(
              videoUrl: Uri.parse('https://www.w3schools.com/tags/mov_bbb.mp4'),
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              useSafeAreaForBottomControls: true,
              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              shapes: VideoPlayerShapeTheme().copyWith(borderRadius: 0),
              colors: VideoPlayerColorScheme().copyWith(
                active: Colors.blueAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
