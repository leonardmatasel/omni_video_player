import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:omni_video_player/src/controllers/global_volume_synchronizer.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_core/omni_video_player_error_view.dart';
import 'package:omni_video_player/src/_core/omni_video_player_thumbnail.dart';

import '../../omni_video_player/models/video_source_configuration.dart';
import '../_vimeo/model/vimeo_video_info.dart';

/// Initializes and builds an [OmniPlaybackController] and player UI.
///
/// Handles:
/// - Async setup of video sources (YouTube, Vimeo, etc.)
/// - Thumbnail loading
/// - Error handling and auto-retry
/// - Volume sync across multiple players (optional)
class OmniVideoPlayerInitializer extends StatefulWidget {
  const OmniVideoPlayerInitializer({
    super.key,
    required this.configuration,
    required this.callbacks,
    required this.buildPlayer,
    this.globalController,
  });

  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;

  /// Called when the player is ready to be built.
  final Widget Function(
    BuildContext context,
    OmniPlaybackController controller,
    ImageProvider<Object>? thumbnail,
  )
  buildPlayer;

  @override
  State<OmniVideoPlayerInitializer> createState() =>
      OmniVideoPlayerInitializerState();
}

class OmniVideoPlayerInitializerState extends State<OmniVideoPlayerInitializer>
    with AutomaticKeepAliveClientMixin<OmniVideoPlayerInitializer> {
  @override
  bool get wantKeepAlive =>
      widget.configuration.videoSourceConfiguration.keepAlive;

  OmniPlaybackController? _controller;
  VimeoVideoInfo? _vimeoInfo;
  ImageProvider<Object>? _thumbnail;

  bool _isLoading = true;
  bool _hasError = false;
  int _errorRetryCount = 0;

  late VideoSourceConfiguration _sourceConfig =
      widget.configuration.videoSourceConfiguration;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 250);
  static const Duration _readyTimeout = Duration(seconds: 30);

  // 🧩 INIT
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // 🔄 PUBLIC REFRESH
  Future<bool> refresh({
    VideoSourceConfiguration? videoSourceConfiguration,
  }) async {
    if (_errorRetryCount >= _maxRetries) {
      setState(() => _hasError = true);
      return false;
    }

    await Future.delayed(_retryDelay);
    debugPrint('Refresh attempt #${_errorRetryCount + 1}');

    setState(() {
      _resetState();
      _errorRetryCount++;
      if (videoSourceConfiguration != null) {
        _sourceConfig = videoSourceConfiguration;
      }
    });

    await _initializePlayer();
    return true;
  }

  void _resetState() {
    _controller = null;
    _isLoading = true;
    _hasError = false;
  }

  // 🚀 INITIALIZATION
  Future<void> _initializePlayer() async {
    try {
      if (_sourceConfig.videoSourceType == VideoSourceType.vimeo) {
        _vimeoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(
          _sourceConfig.videoId!,
        );
        if (_vimeoInfo == null) throw Exception('Failed to fetch Vimeo info');
      }

      final initStrategy = OmniVideoPlayerInitializerFactory.getStrategy(
        _sourceConfig.videoSourceType,
        _sourceConfig,
        widget.configuration,
        widget.callbacks,
        widget.globalController,
      );

      _thumbnail = await _loadThumbnail();
      if (mounted) setState(() {});

      _controller = await initStrategy.initialize();
      if (_controller != null) _startReadyTimeout(_controller!);
    } catch (e, st) {
      debugPrint('Video initialization error: $e\n$st');
      _hasError = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ⏱️ FAILSAFE: mark as error if controller not ready within timeout
  void _startReadyTimeout(OmniPlaybackController controller) {
    Future.delayed(_readyTimeout, () {
      if (mounted && !controller.isReady) {
        setState(() {
          refresh();
          _hasError = true;
          _isLoading = false;
        });
      }
    });
  }

  // 🎨 UI BUILD
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OmniVideoPlayerTheme.of(context)!;
    final aspectRatio = _calculateAspectRatio();

    if (_isLoading) return _buildLoadingView(theme, aspectRatio);
    if (_hasError || _controller == null) return _buildErrorView(theme);

    final player = widget.buildPlayer(context, _controller!, _thumbnail);
    return _buildWithVolumeSync(player);
  }

  Widget _buildWithVolumeSync(Widget child) {
    final shouldSync = widget
        .configuration
        .videoSourceConfiguration
        .synchronizeMuteAcrossPlayers;

    if (!shouldSync || _controller == null) return child;

    return GlobalVolumeSynchronizer(controller: _controller!, child: child);
  }

  double _calculateAspectRatio() {
    final customRatio =
        widget.configuration.playerUIVisibilityOptions.customAspectRatioNormal;

    if (customRatio != null) return customRatio;
    if (_controller != null) {
      final size = _controller!.size;
      return size.width / size.height;
    }
    return 16 / 9;
  }

  // 🧩 UI COMPONENTS
  Widget _buildLoadingView(OmniVideoPlayerThemeData theme, double aspectRatio) {
    final showThumbnail =
        widget.configuration.playerUIVisibilityOptions.showThumbnailAtStart;

    final hasThumb =
        widget.configuration.customPlayerWidgets.thumbnail != null ||
        _thumbnail != null;

    return Stack(
      children: [
        if (showThumbnail && hasThumb)
          Align(
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
                child: VideoPlayerThumbnail(
                  imageProvider:
                      widget.configuration.customPlayerWidgets.thumbnail ??
                      _thumbnail!,
                  fit: widget.configuration.customPlayerWidgets.thumbnailFit,
                  backgroundColor: theme.colors.backgroundThumbnail,
                ),
              ),
            ),
          ),
        if (widget.configuration.playerUIVisibilityOptions.showLoadingWidget)
          Align(
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
              child: Center(
                child: widget.configuration.customPlayerWidgets.loadingWidget,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView(OmniVideoPlayerThemeData theme) {
    final showError =
        widget.configuration.playerUIVisibilityOptions.showErrorPlaceholder;

    if (!showError) return const SizedBox.shrink();

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.shapes.borderRadius),
        child:
            widget.configuration.customPlayerWidgets.errorPlaceholder ??
            const OmniVideoPlayerErrorView(),
      ),
    );
  }

  // 🖼️ THUMBNAIL HELPERS
  Future<ImageProvider<Object>?> _loadThumbnail() async {
    if (!widget.configuration.playerUIVisibilityOptions.showThumbnailAtStart) {
      return null;
    }

    switch (_sourceConfig.videoSourceType) {
      case VideoSourceType.youtube:
        return await YouTubeService().loadYoutubeThumbnail(
          _sourceConfig.videoUrl?.toString(),
        );
      case VideoSourceType.vimeo:
        return _vimeoInfo != null
            ? NetworkImage(_vimeoInfo!.thumbnailUrl)
            : null;
      case VideoSourceType.network:
      case VideoSourceType.asset:
      case VideoSourceType.file:
        return widget.configuration.customPlayerWidgets.thumbnail;
    }
  }
}
