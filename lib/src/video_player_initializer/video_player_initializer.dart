import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/controllers/global_volume_synchronizer.dart';
import 'package:omni_video_player/src/utils/logger.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/src/widgets/player/video_player_error_placeholder.dart';
import 'package:omni_video_player/src/widgets/player/video_player_thumbnail_preview.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../omni_video_player/models/video_source_configuration.dart';
import '../vimeo/model/vimeo_video_info.dart';

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
  ImageProvider<Object>? _thumbnail;
  late VideoSourceConfiguration _videoSourceConfiguration =
      widget.options.videoSourceConfiguration;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> refresh(
      {VideoSourceConfiguration? videoSourceConfiguration}) async {
    setState(() {
      _controller = null;
      _isLoading = true;
      _hasError = false;
      if (videoSourceConfiguration != null) {
        _videoSourceConfiguration = videoSourceConfiguration;
      }
    });
    await _initialize();
  }

  Future<void> _initialize() async {
    final type = _videoSourceConfiguration.videoSourceType;
    if (type == VideoSourceType.vimeo) {
      _vimeoVideoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(
        _videoSourceConfiguration.videoId!,
      );

      if (_vimeoVideoInfo == null) {
        throw Exception('Failed to fetch Vimeo video info');
      }
    }

    final strategy = VideoPlayerInitializerFactory.getStrategy(
      type,
      _videoSourceConfiguration,
      widget.options,
      widget.callbacks,
      widget.globalController,
      () => _hasError = true,
    );

    try {
      _thumbnail = await _getThumbnail();
      setState(() {});
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
    Future.delayed(_videoSourceConfiguration.timeoutDuration, () {
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

    final aspectRatio =
        widget.options.playerUIVisibilityOptions.customAspectRatioNormal ??
            (_controller != null
                ? (_controller!.size.width / _controller!.size.height)
                : 16 / 9);

    if (_isLoading) {
      return Stack(
        children: [
          if ((widget.options.customPlayerWidgets.thumbnail != null ||
                  _thumbnail != null) &&
              widget.options.playerUIVisibilityOptions.showThumbnailAtStart)
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(theme.shapes.borderRadius),
                  child: VideoPlayerThumbnailPreview(
                    imageProvider:
                        widget.options.customPlayerWidgets.thumbnail ??
                            _thumbnail!,
                    fit: widget.options.customPlayerWidgets.thumbnailFit,
                    backgroundColor: theme.colors.backgroundThumbnail,
                  ),
                ),
              ),
            ),
          if (widget.options.playerUIVisibilityOptions.showLoadingWidget)
            widget.options.customPlayerWidgets.loadingWidget
          else
            const SizedBox.shrink(),
        ],
      );
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
      _thumbnail,
    );

    return widget.options.globalPlaybackControlSettings
                .synchronizeMuteAcrossPlayers &&
            widget.options.globalPlaybackControlSettings
                .useGlobalPlaybackController
        ? GlobalVolumeSynchronizer(controller: _controller!, child: child)
        : child;
  }

  Future<ImageProvider<Object>?> _getYoutubeThumbnail(String? url) async {
    if (url == null) return null;

    try {
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        return NetworkImage(url);
      } else {
        return null; // non creo l'immagine se non esiste
      }
    } catch (e) {
      return null; // errore di rete → niente thumbnail
    }
  }

  Future<ImageProvider<Object>?> _getThumbnail() async {
    if (!widget.options.playerUIVisibilityOptions.showThumbnailAtStart) {
      return null;
    }

    switch (_videoSourceConfiguration.videoSourceType) {
      case VideoSourceType.youtube:
        final videoId = VideoId(
          _videoSourceConfiguration.videoUrl!.toString(),
        ).value;
        return await _getYoutubeThumbnail(
            "https://i3.ytimg.com/vi/$videoId/sddefault.jpg");

      case VideoSourceType.vimeo:
        return _vimeoVideoInfo != null
            ? NetworkImage(_vimeoVideoInfo!.thumbnailUrl)
            : null;

      case VideoSourceType.network:
        return widget.options.customPlayerWidgets.thumbnail;

      case VideoSourceType.asset:
        return widget.options.customPlayerWidgets.thumbnail;

      case VideoSourceType.file:
        return widget.options.customPlayerWidgets.thumbnail;
    }
  }
}
