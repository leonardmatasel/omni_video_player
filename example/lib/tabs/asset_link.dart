import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class AssetLink extends StatelessWidget {
  const AssetLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent,
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.asset(
              videoDataSource: 'assets/sample.mp4',
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              enableZoom: true,
              useSafeAreaForBottomControls: true,
              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: CircularProgressIndicator(color: Colors.black),
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
