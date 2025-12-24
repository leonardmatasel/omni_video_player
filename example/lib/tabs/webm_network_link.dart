import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class WebmNetworkLink extends StatelessWidget {
  const WebmNetworkLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.network(
              videoUrl: Uri.parse(
                'https://wiki.yoctoproject.org/wiki/images/a/a6/Big-buck-bunny_trailer.webm',
              ),
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              useSafeAreaForBottomControls: true,
              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: CircularProgressIndicator(color: Colors.white),
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
