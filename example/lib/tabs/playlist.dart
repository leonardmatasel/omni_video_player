import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player.dart';

class PlaylistExample extends StatelessWidget {
  const PlaylistExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: OmniVideoPlaylist(
          playlistConfiguration: PlaylistConfiguration(
            items: [
              OmniPlaylistItem(
                sourceConfiguration: VideoSourceConfiguration.network(
                  videoUrl: Uri.parse(
                    'https://www.w3schools.com/tags/mov_bbb.mp4',
                  ),
                ),
                title: 'Big Buck Bunny',
                subtitle: 'W3Schools Sample',
                thumbnail: NetworkImage(
                  "https://zxpromptpullzone.b-cdn.net/prompt-images/1780212898239_1000083496.jpg",
                ),
              ),
              OmniPlaylistItem(
                sourceConfiguration: VideoSourceConfiguration.youtube(
                  videoUrl: Uri.parse(
                    'https://youtu.be/y63LOwXBykI?si=o3Bh6y0FtoFJGXcU',
                  ),
                  enableYoutubeWebViewFallback: true,
                ),
                thumbnail: NetworkImage(
                  "https://firebasestorage.googleapis.com/v0/b/zxprompt-bb26e.firebasestorage.app/o/prompt-images%2F1773399046109_1000067430.png?alt=media&token=4bd5bc0c-51c0-43ae-918d-1b62e13c4ac6",
                ),

                title: 'YouTube Video 1',
                subtitle: 'YouTube',
              ),
              OmniPlaylistItem(
                sourceConfiguration: VideoSourceConfiguration.youtube(
                  videoUrl: Uri.parse(
                    'https://youtu.be/o2mStNt3gJw?si=UIizj_CgzLTzSfpN',
                  ),
                ),

                title: 'Elephants Dream',
                subtitle: 'Blender Foundation',
                thumbnail: NetworkImage(
                  "https://zxpromptpullzone.b-cdn.net/prompt-images/1779381056116_1000081925.jpg",
                ),
              ),
              OmniPlaylistItem(
                sourceConfiguration: VideoSourceConfiguration.youtube(
                  videoUrl: Uri.parse(
                    'https://youtu.be/I18-RAJk6Po?si=EMEtRPbS2bG25V12',
                  ),
                  //  enableYoutubeWebViewFallback: true,
                ),
                title: 'YouTube Video 2',
                subtitle: 'YouTube',
                thumbnail: NetworkImage(
                  "https://zxpromptpullzone.b-cdn.net/prompt-images/1780212898239_1000083496.jpg",
                ),
              ),
              OmniPlaylistItem(
                sourceConfiguration: VideoSourceConfiguration.vimeo(
                  videoId: "734334481",
                  //  enableYoutubeWebViewFallback: true,
                ),
                title: 'Vimeo Video 1',
                subtitle: 'Vimeo',
                thumbnail: NetworkImage(
                  "https://res.cloudinary.com/dgancvfml/image/upload/v1766309628/szqh5yo6fyqx3uhw7ogy.jpg",
                ),
              ),
            ],
            autoAdvance: true,
            advanceDelay: const Duration(seconds: 5),
            repeatMode: PlaylistRepeatMode.none,
          ),
          playerConfiguration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.network(
              videoUrl: Uri.parse('https://www.w3schools.com/tags/mov_bbb.mp4'),
            ).copyWith(autoPlay: true),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              useSafeAreaForBottomControls: true,

              showPlaybackSpeedButton: true,
            ),
            customPlayerWidgets: CustomPlayerWidgets().copyWith(
              loadingWidget: const CircularProgressIndicator(
                color: Colors.white,
              ),
              fullscreenWrapper: (context, child) {
                return _OrientationReverter(child: child);
              },
            ),
            playerTheme: OmniVideoPlayerThemeData().copyWith(
              shapes: VideoPlayerShapeTheme().copyWith(borderRadius: 0),
            ),
          ),
          callbacks: VideoPlayerCallbacks(
            onControllerCreated: (controller) {
              if (kDebugMode) {
                print('PLAYLIST: Controller created');
              }
            },
            onFinished: () {
              if (kDebugMode) {
                print('PLAYLIST: Video finished');
              }
            },
          ),
          playlistCallbacks: PlaylistCallbacks(
            onVideoChanged: (index, item) {
              if (kDebugMode) {
                print('PLAYLIST: Now playing index $index — ${item.title}');
              }
            },
            onPlaylistFinished: () {
              if (kDebugMode) {
                print('PLAYLIST: All videos finished');
              }
            },
            onAdvancing: (from, to) {
              if (kDebugMode) {
                print('PLAYLIST: Advancing from $from to $to');
              }
            },
          ),
          onPlaylistControllerCreated: (controller) {
            if (kDebugMode) {
              print(
                'PLAYLIST: Controller ready — ${controller.itemCount} items',
              );
            }
          },
          showPlaylistPanelInFullscreen: true,
          showNavigationOverlay: true,
        ),
      ),
    );
  }
}

class _OrientationReverter extends StatefulWidget {
  final Widget child;
  const _OrientationReverter({required this.child});

  @override
  State<_OrientationReverter> createState() => _OrientationReverterState();
}

class _OrientationReverterState extends State<_OrientationReverter> {
  @override
  void dispose() {
    // We need to defer orientation restoration to after [OmniVideoPlayerFullscreen.dispose()]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
