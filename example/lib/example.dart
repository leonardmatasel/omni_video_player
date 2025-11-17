import 'package:flutter/material.dart';

import 'package:omni_video_player/omni_video_player.dart';

/// Entry point of the app.
void main() {
  OmniVideoPlayer.ensureInitialized();
  runApp(MyApp());
}

/// Main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      theme: ThemeData.dark(),
      home: const VideoScreen(),
    );
  }
}

/// A simple screen showing a YouTube video player with a play/pause button.
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  /// Controller that provides playback control (play, pause, etc.).
  OmniPlaybackController? _controller;

  void _update() {
    // Schedule the UI update after the current build frame completes.
    // This prevents "setState() called during build" errors and ensures
    // the widget rebuilds safely once the frame has finished rendering.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Video')),

      // The layout consists of the video player and a control button.
      body: Column(
        children: [
          Expanded(
            child: OmniVideoPlayer(
              // Callbacks
              callbacks: VideoPlayerCallbacks(
                onControllerCreated: (controller) {
                  _controller?.removeListener(_update);
                  _controller = controller..addListener(_update);
                },
                onFullScreenToggled: (isFullScreen) {},
                onOverlayControlsVisibilityChanged: (areVisible) {},
                onCenterControlsVisibilityChanged: (areVisible) {},
                onMuteToggled: (isMute) {},
                onSeekStart: (pos) {},
                onSeekEnd: (pos) {},
                onSeekRequest: (target) => true,
                onFinished: () {},
                onReplay: () {},
              ),

              // Full configuration: playing a YouTube video.
              configuration: VideoPlayerConfiguration(
                videoSourceConfiguration: VideoSourceConfiguration.youtube(
                  videoUrl: Uri.parse(
                    'https://www.youtube.com/watch?v=cuqZPx0H7a0',
                  ),
                  preferredQualities: [
                    OmniVideoQuality.high720,
                    OmniVideoQuality.low144,
                  ],
                  availableQualities: [
                    OmniVideoQuality.high1080,
                    OmniVideoQuality.high720,
                    OmniVideoQuality.medium480,
                    OmniVideoQuality.medium360,
                    OmniVideoQuality.low144,
                  ],
                  enableYoutubeWebViewFallback: true,
                  forceYoutubeWebViewOnly: false,
                ).copyWith(
                  autoPlay: false,
                  initialPosition: Duration.zero,
                  initialVolume: 1.0,
                  initialPlaybackSpeed: 1.0,
                  availablePlaybackSpeed: [0.5, 1.0, 1.25, 1.5, 2.0],
                  autoMuteOnStart: false,
                  allowSeeking: true,
                  synchronizeMuteAcrossPlayers: true,
                  timeoutDuration: const Duration(seconds: 30),
                ),
                playerTheme: OmniVideoPlayerThemeData().copyWith(
                  icons: VideoPlayerIconTheme().copyWith(
                    error: Icons.warning,
                    playbackSpeedButton: Icons.speed,
                  ),
                  overlays: VideoPlayerOverlayTheme().copyWith(
                    backgroundColor: Colors.white,
                    alpha: 25,
                  ),
                ),
                playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
                  showSeekBar: true,
                  showCurrentTime: true,
                  showDurationTime: true,
                  showRemainingTime: true,
                  showLiveIndicator: true,
                  showLoadingWidget: true,
                  showErrorPlaceholder: true,
                  showReplayButton: true,
                  showThumbnailAtStart: true,
                  showVideoBottomControlsBar: true,
                  showBottomControlsBarOnEndedFullscreen: true,
                  showFullScreenButton: true,
                  showSwitchVideoQuality: true,
                  showSwitchWhenOnlyAuto: true,
                  showPlaybackSpeedButton: true,
                  showMuteUnMuteButton: true,
                  showPlayPauseReplayButton: true,
                  useSafeAreaForBottomControls: true,
                  showGradientBottomControl: true,
                  enableForwardGesture: true,
                  enableBackwardGesture: true,
                  enableExitFullscreenOnVerticalSwipe: true,
                  enableOrientationLock: true,
                  controlsPersistenceDuration: const Duration(seconds: 3),
                  customAspectRatioNormal: null,
                  customAspectRatioFullScreen: null,
                  fullscreenOrientation: null,
                  showBottomControlsBarOnPause: false,
                  alwaysShowBottomControlsBar: false,
                  fitVideoToBounds: true,
                ),
                customPlayerWidgets: CustomPlayerWidgets().copyWith(
                  loadingWidget: CircularProgressIndicator(color: Colors.red),
                  errorPlaceholder: null,
                  bottomControlsBar: null,
                  leadingBottomButtons: null,
                  trailingBottomButtons: null,
                  customSeekBar: null,
                  customDurationDisplay: null,
                  customRemainingTimeDisplay: null,
                  thumbnail: null,
                  thumbnailFit: null,
                  customOverlayLayers: null,
                  fullscreenWrapper: null,
                ),
                liveLabel: "LIVE",
                enableBackgroundOverlayClip: true,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) {
                // If the controller isn't ready yet, show a loading spinner.
                if (_controller == null) {
                  return const CircularProgressIndicator();
                }

                final isPlaying = _controller!.isPlaying;

                // Button that toggles playback.
                return ElevatedButton.icon(
                  onPressed: () {
                    isPlaying ? _controller!.pause() : _controller!.play();
                  },
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(isPlaying ? 'Pause' : 'Play'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
