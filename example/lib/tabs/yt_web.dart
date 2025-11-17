import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class YTWeb extends StatelessWidget {
  const YTWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onSeekStart: (position) {
              if (kDebugMode) {
                print('OMNI PLAYER: Seek started at: $position');
              }
            },
            onSeekEnd: (position) {
              if (kDebugMode) {
                print('OMNI PLAYER: Seek ended at: $position');
              }
            },
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.youtube(
              videoUrl: Uri.parse(
                'https://www.youtube.com/watch?v=pt8VYOfr8To',
              ),
              preferredQualities: [
                OmniVideoQuality.high720,
                OmniVideoQuality.medium480,
              ],
              forceYoutubeWebViewOnly: true,
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
              useSafeAreaForBottomControls: true,
              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              thumbnailFit: BoxFit.fitWidth,
              loadingWidget: CircularProgressIndicator(color: Colors.white),
            ),
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              icons: VideoPlayerIconTheme().copyWith(error: Icons.warning),
              overlays: VideoPlayerOverlayTheme().copyWith(
                backgroundColor: Colors.white,
                alpha: 100,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
