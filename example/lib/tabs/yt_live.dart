import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class YTLive extends StatelessWidget {
  const YTLive({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.youtube(
              videoUrl: Uri.parse(
                'https://www.youtube.com/watch?v=Cp4RRAEgpeU',
              ),
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              thumbnailFit: BoxFit.fitWidth,
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              showLiveIndicator: true,
              showFullScreenButton: true,
              showGradientBottomControl: true,
              useSafeAreaForBottomControls: true,
            ),
            liveLabel: 'LIVE SANTA CLAUS VILLAGE',
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              colors: VideoPlayerColorScheme().copyWith(
                liveIndicator: Colors.white,
              ),
              overlays: VideoPlayerOverlayTheme().copyWith(
                backgroundColor: Colors.black,
                alpha: 100,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
