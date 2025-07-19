import 'package:flutter/material.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/controllers/global_volume_synchronizer.dart';
import 'package:omni_video_player/src/models/vimeo_video_info.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/src/widgets/player/video_player_error_placeholder.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:omni_video_player/src/utils/logger.dart';

class VideoPlayerInitializer extends StatefulWidget {
  const VideoPlayerInitializer({
    super.key,
    required this.options,
    required this.callbacks,
    required this.buildPlayer,
    this.globalController,
  });

  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;

  final GlobalPlaybackController? globalController;
  final Widget Function(
    BuildContext context,
    OmniPlaybackController controller,
    ImageProvider<Object>? thumbnail,
  ) buildPlayer;

  @override
  State<VideoPlayerInitializer> createState() => VideoPlayerInitializerState();
}

class VideoPlayerInitializerState extends State<VideoPlayerInitializer>
    with AutomaticKeepAliveClientMixin<VideoPlayerInitializer> {
  @override
  bool get wantKeepAlive => true;

  OmniPlaybackController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  VimeoVideoInfo? _vimeoVideoInfo;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> refresh() async {
    setState(() {
      _controller = null;
      _isLoading = true;
      _hasError = false;
    });
    await _initialize();
  }

  Future<void> _initialize() async {
    final type = widget.options.videoSourceConfiguration.videoSourceType;
    if (type == VideoSourceType.vimeo) {
      _vimeoVideoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(
        widget.options.videoSourceConfiguration.videoId!,
      );

      if (_vimeoVideoInfo == null) {
        throw Exception('Failed to fetch Vimeo video info');
      }
    }

    final strategy = VideoPlayerInitializerFactory.getStrategy(
      type,
      widget.options,
      widget.callbacks,
      widget.globalController,
      () => setState(() => _hasError = true),
    );

    try {
      _controller = await strategy.initialize();
      if (_controller == null) {
        throw Exception('Failed to initialize video player');
      }
      _startReadyTimeout(_controller!);
    } catch (e, stack) {
      logger.e("Initialization failed", error: e, stackTrace: stack);
      _hasError = true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startReadyTimeout(OmniPlaybackController controller) {
    Future.delayed(widget.options.videoSourceConfiguration.timeoutDuration, () {
      if (mounted && !controller.isReady) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OmniVideoPlayerTheme.of(context)!;

    if (_isLoading) {
      return widget.options.playerUIVisibilityOptions.showLoadingWidget
          ? widget.options.customPlayerWidgets.loadingWidget
          : const SizedBox.shrink();
    }

    if (_hasError || _controller == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
        child: widget.options.playerUIVisibilityOptions.showErrorPlaceholder
            ? widget.options.customPlayerWidgets.errorPlaceholder ??
                VideoPlayerErrorPlaceholder(
                  playerGlobalKey: widget.options.globalKeyInitializer,
                  showRefreshButton: widget.options.playerUIVisibilityOptions
                      .showRefreshButtonInErrorPlaceholder,
                  videoUrlToOpenExternally: widget
                      .options.videoSourceConfiguration.videoUrl
                      .toString(),
                )
            : const SizedBox.shrink(),
      );
    }

    final child = widget.buildPlayer(
      context,
      _controller!,
      widget.options.playerUIVisibilityOptions.showThumbnailAtStart
          ? _getThumbnail()
          : null,
    );

    return widget.options.globalPlaybackControlSettings
                .synchronizeMuteAcrossPlayers &&
            widget.options.globalPlaybackControlSettings
                .useGlobalPlaybackController
        ? GlobalVolumeSynchronizer(controller: _controller!, child: child)
        : child;
  }

  ImageProvider<Object>? _getThumbnail() {
    if (!widget.options.playerUIVisibilityOptions.showThumbnailAtStart) {
      return null;
    }

    switch (widget.options.videoSourceConfiguration.videoSourceType) {
      case VideoSourceType.youtube:
        final videoId = VideoId(
          widget.options.videoSourceConfiguration.videoUrl!.toString(),
        ).value;
        return NetworkImage("https://i3.ytimg.com/vi/$videoId/sddefault.jpg");

      case VideoSourceType.vimeo:
        return _vimeoVideoInfo != null
            ? NetworkImage(_vimeoVideoInfo!.thumbnailUrl)
            : null;

      case VideoSourceType.network:
        return widget.options.customPlayerWidgets.thumbnail;

      case VideoSourceType.asset:
        return widget.options.customPlayerWidgets.thumbnail;
    }
  }
}
