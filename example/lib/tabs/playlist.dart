import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class Playlist extends StatelessWidget {
  const Playlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: OmniVideoPlaylist(
          playlistConfiguration: PlaylistConfiguration(
            autoAdvance: true,
            loop: true,
            items: [
              VideoSourceConfiguration.youtube(
                videoUrl: Uri.parse(
                  'https://www.youtube.com/watch?v=djV11Xbc914',
                ),
              ),
              VideoSourceConfiguration.youtube(
                videoUrl: Uri.parse(
                  'https://www.youtube.com/watch?v=Zi_XLOBDo_Y',
                ),
              ),
              VideoSourceConfiguration.youtube(
                videoUrl: Uri.parse(
                  'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
                ),
              ),
            ],
          ),
          playerConfiguration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.youtube(
              videoUrl: Uri.parse(
                'https://www.youtube.com/watch?v=djV11Xbc914',
              ),
            ),
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              colors: VideoPlayerColorScheme().copyWith(
                controlButtonBackground: Colors.deepPurple,
                controlButtonIcon: Colors.white,
              ),
              icons: VideoPlayerIconTheme().copyWith(
                skipPrevious: Icons.fast_rewind_rounded,
                skipNext: Icons.fast_forward_rounded,
              ),
              accessibility: VideoPlayerAccessibilityTheme().copyWith(
                previousTrackLabel: 'Previous song',
                nextTrackLabel: 'Next song',
              ),
            ),
          ),
          callbacks: VideoPlayerCallbacks(),
          playlistCallbacks: PlaylistCallbacks(
            onVideoChanged: (index) => debugPrint('Playlist: now at $index'),
            onPlaylistCompleted: () => debugPrint('Playlist: completed'),
          ),
        ),
      ),
    );
  }
}
