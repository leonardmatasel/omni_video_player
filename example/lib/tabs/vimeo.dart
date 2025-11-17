import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class Vimeo extends StatefulWidget {
  const Vimeo({super.key});

  @override
  State<Vimeo> createState() => _VimeoState();
}

class _VimeoState extends State<Vimeo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: OmniVideoPlayer(
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              // For more details, see example/lib/example.dart or refer to the "Sync UI" section in the README.
            },
            onFullScreenToggled: (isFullScreen) {
              if (kDebugMode) {
                print('OMNI PLAYER: Fullscreen toggled: $isFullScreen');
              }
            },
            onMuteToggled: (isMuted) {
              if (kDebugMode) {
                print('OMNI PLAYER: Mute toggled: $isMuted');
              }
            },
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
            onFinished: () {
              if (kDebugMode) {
                print('OMNI PLAYER: Video finished');
              }
            },
            onReplay: () {
              if (kDebugMode) {
                print('OMNI PLAYER: Video replayed');
              }
            },
          ),
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.vimeo(
              videoId: '1017406920',
            ).copyWith(initialVolume: 0.8),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              useSafeAreaForBottomControls: true,
              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: CircularProgressIndicator(color: Colors.white),
            ),
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              overlays: VideoPlayerOverlayTheme().copyWith(
                backgroundColor: Colors.white,
                alpha: 100,
              ),
              shapes: VideoPlayerShapeTheme().copyWith(borderRadius: 0),
            ),
          ),
        ),
      ),
    );
  }
}
