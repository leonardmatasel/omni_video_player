import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class YT extends StatelessWidget {
  const YT({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onSeekStart: (position) {
              print('OMNI PLAYER: Seek started at: $position');
            },
            onSeekEnd: (position) {
              print('OMNI PLAYER: Seek ended at: $position');
            },
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
          ),
          options: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.youtube(
              videoUrl: Uri.parse(
                'https://www.youtube.com/watch?v=QN1odfjtMoo',
              ),
              preferredQualities: [720, 480],
            ),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
              useSafeAreaForBottomControls: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              thumbnailFit: BoxFit.contain,
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
