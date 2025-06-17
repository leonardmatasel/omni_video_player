import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// Entry point of the app.
/// Wraps the app with a [BlocProvider] for global video playback coordination.
void main() {
  runApp(
    BlocProvider(
      create: (_) => GlobalPlaybackController(),
      child: const MyApp(),
    ),
  );
}

/// Main application widget.
/// Applies a dark theme and launches the [VideoScreen].
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Video')),

      // The layout consists of the video player and a control button.
      body: Column(
        children: [
          // Expands to fill available vertical space.
          Expanded(
            child: OmniVideoPlayer(
              // Called when the internal video controller is ready.
              callbacks: VideoPlayerCallbacks(
                onControllerCreated: (controller) {
                  _controller = controller;

                  // We call setState to trigger a rebuild so that
                  // the play/pause button below knows the controller is ready.
                  setState(() {});
                },
              ),

              // Minimal configuration: playing a YouTube video.
              options: VideoPlayerConfiguration(
                videoSourceConfiguration: VideoSourceConfiguration.youtube(
                  videoUrl: Uri.parse(
                    'https://www.youtube.com/watch?v=cuqZPx0H7a0',
                  ),
                  preferredQualities: [720, 480],
                ),
                playerTheme: OmniVideoPlayerThemeData().copyWith(
                  icons: VideoPlayerIconTheme().copyWith(error: Icons.warning),
                  overlays: VideoPlayerOverlayTheme().copyWith(
                    backgroundColor: Colors.white,
                    alpha: 25,
                  ),
                ),
                playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
                  showMuteUnMuteButton: true,
                  showFullScreenButton: true,
                  useSafeAreaForBottomControls: true,
                ),
                customPlayerWidgets: CustomPlayerWidgets().copyWith(
                  thumbnailFit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// A play/pause button that updates dynamically based on the controller state.
          ///
          /// [AnimatedBuilder] is used here to listen to the [OmniPlaybackController],
          /// which is a [Listenable]. When `play`, `pause`, or other playback changes occur,
          /// the builder function is called, updating the UI automatically.
          ///
          /// Using [AnimatedBuilder] avoids manual `setState()` calls for every controller change.
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller]),
              builder: (context, _) {
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
