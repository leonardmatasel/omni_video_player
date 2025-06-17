import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer.dart';
import 'package:omni_video_player/src/widgets/video_player_renderer.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A universal and configurable video player widget supporting multiple video sources.
///
/// The [OmniVideoPlayer] is a stateless widget that integrates
/// video playback capabilities from various content types such as:
/// - YouTube
/// - Vimeo
/// - Twitch *(planned)*
/// - TikTok *(planned)*
/// - Dailymotion *(planned)*
/// - Streamable *(planned)*
/// — Online/direct URLs
/// - Local videos
///
/// This widget acts as a façade, orchestrating theming, controller
/// initialization, global playback coordination, and UI rendering.
///
/// It also supports thumbnail previews, custom callback hooks, and
/// automatic theme injection.
///
/// Example usage:
/// ```dart
/// OmniVideoPlayer(
///   options: VideoPlayerOptions(
///     videoUrl: Uri.parse("https://example.com/video.mp4"),
///     videoSourceType: VideoSourceType.network,
///     playerTheme: const OmniVideoPlayerThemeData.dark(),
///     useGlobalController: true,
///   ),
///   callbacks: VideoPlayerCallbacks(
///     onControllerCreated: (controller) {
///       controller.play();
///     },
///   ),
/// )
/// `
class OmniVideoPlayer extends StatefulWidget {
  /// Creates a new instance of [OmniVideoPlayer].
  ///
  /// The [options] parameter defines how the video player should behave
  /// and what kind of video content to load. The [callbacks] parameter
  /// allows hooking into player lifecycle events.
  const OmniVideoPlayer({
    super.key,
    required this.options,
    required this.callbacks,
  });

  /// The playback configuration and source definition.
  final VideoPlayerConfiguration options;

  /// Callback hooks for reacting to controller state changes and events.
  final VideoPlayerCallbacks callbacks;

  @override
  State<OmniVideoPlayer> createState() => _OmniVideoPlayerState();
}

class _OmniVideoPlayerState extends State<OmniVideoPlayer> {
  late VideoPlayerConfiguration _options;
  late VideoPlayerCallbacks _callbacks;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _callbacks = widget.callbacks;
  }

  @override
  void didUpdateWidget(covariant OmniVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.videoSourceConfiguration.videoSourceType !=
        oldWidget.options.videoSourceConfiguration.videoSourceType) {
      setState(() {
        _options = widget.options;
        _callbacks = widget.callbacks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalController =
        _options.globalPlaybackControlSettings.useGlobalPlaybackController
            ? context.watch<GlobalPlaybackController>()
            : null;

    return OmniVideoPlayerTheme(
      data: _options.playerTheme,
      child: VideoPlayerInitializer(
        key: _options.globalKeyInitializer,
        options: _options,
        callbacks: _callbacks,
        globalController: globalController,
        buildPlayer: (context, controller, thumbnail) => Container(
          alignment: Alignment.center,
          child: Stack(
            children: [
              if (_options.playerUIVisibilityOptions.showLoadingWidget &&
                  !controller.isReady)
                Center(child: _options.customPlayerWidgets.loadingWidget),
              VideoPlayerRenderer(
                options: _options.copyWith(
                  customPlayerWidgets: _options.customPlayerWidgets.copyWith(
                    thumbnail:
                        _options.customPlayerWidgets.thumbnail ?? thumbnail,
                  ),
                ),
                callbacks: _callbacks,
                controller: controller,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
