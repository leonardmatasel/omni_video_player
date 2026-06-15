import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class YT extends StatefulWidget {
  YT({super.key});

  @override
  State<YT> createState() => _YTState();
}

class _YTState extends State<YT> {
  List<String> ytVideoUrl = [
    "https://youtu.be/y63LOwXBykI?si=o3Bh6y0FtoFJGXcU",
    "https://youtu.be/sIKQiJIm0hY?si=UxP8kEepFmGMkIDd",
    "https://youtu.be/NFsEqOBG51M?si=15JuFQROIX2cbl5A",
    "https://youtu.be/CbFjVMEZA5k?si=AjTUt-N_p7GSInvV",
  ];

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (index == 0) {
                  } else {
                    index--;
                  }
                  setState(() {});
                },
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
              Text(index.toString(), style: TextStyle(color: Colors.white)),
              IconButton(
                onPressed: () {
                  if (index == ytVideoUrl.length) {
                  } else {
                    index++;
                  }
                  setState(() {});
                },
                icon: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
          OmniVideoPlayer(
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
              onFinished: () {
                if (kDebugMode) {
                  print('OMNI PLAYER: Video finished');
                }
              },
              onReplay: () {
                if (kDebugMode) {
                  print('OMNI PLAYwER: Video replayed');
                }
              },
            ),
            configuration: VideoPlayerConfiguration(
              videoSourceConfiguration: VideoSourceConfiguration.youtube(
                videoUrl: Uri.parse(ytVideoUrl[index]),
                preferredQualities: [
                  OmniVideoQuality.high720,
                  OmniVideoQuality.medium480,
                ],
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
                backdrop: VideoPlayerBackdropTheme().copyWith(
                  backgroundColor: Colors.white,
                  alpha: 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
