import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class NetworkLink extends StatelessWidget {
  const NetworkLink({super.key});

  // Example: create 50 different video URLs (replace with your own links)
  static List<String> get _videoUrls => List.generate(
    50,
    (index) => 'https://www.w3schools.com/tags/mov_bbb.mp4',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: _videoUrls.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final videoUrl = _videoUrls[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 250,
            color: Colors.grey.shade900,
            child: Center(
              child: OmniVideoPlayer(
                key: ValueKey('video_$index'),
                callbacks: VideoPlayerCallbacks(
                  onControllerCreated: (controller) {
                    // You can add global logging or management here
                  },
                ),
                options: VideoPlayerConfiguration(
                  videoSourceConfiguration: VideoSourceConfiguration.network(
                    videoUrl: Uri.parse(videoUrl),
                  ),
                  playerUIVisibilityOptions: PlayerUIVisibilityOptions(
                    useSafeAreaForBottomControls: true,
                    showPlaybackSpeedButton: true,
                  ),
                  customPlayerWidgets: CustomPlayerWidgets().copyWith(
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
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
        },
      ),
    );
  }
}
