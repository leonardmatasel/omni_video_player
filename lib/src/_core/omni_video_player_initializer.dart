import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:omni_video_player/src/controllers/global_volume_synchronizer.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_core/omni_video_player_error_view.dart';
import 'package:omni_video_player/src/_core/omni_video_player_thumbnail.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

  /// Budget for init/playback/network recovery attempts.
  int _errorRetryCount = 0;

  /// Separate budget for hardware-decoder exhaustion retries, so a couple of
  /// decoder blips don't silently burn the network/playback recovery budget.
  int _decoderRetryCount = 0;

  /// Guards against re-entrant recovery while a playback-error refresh is in
  /// flight (the controller keeps notifying `hasError` until it is replaced).
  bool _recovering = false;

  /// Position where the last playback error happened. The retry budget is
  /// restored only once playback advances well past it (proof the source now
  /// serves that region), so a server that fails every seek can't reset the
  /// budget on the brief ready→error flicker and loop forever.
  Duration _lastErrorPosition = Duration.zero;

  /// True while the controller has been released because the player scrolled
  /// out of view; it re-initializes when it returns on screen.
  bool _releasedOffView = false;

  /// Cancelable failsafe timer (A5): fires [refresh] if the controller never
  /// becomes ready. Cancelled once it is ready, on reset, and on dispose so it
  /// can't fire against a stale controller.
  Timer? _readyTimeoutTimer;

  late VideoSourceConfiguration _sourceConfig =
      widget.configuration.videoSourceConfiguration;

  static const int _maxRetries = 2;
  static const int _maxDecoderRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 250);
  static const Duration _readyTimeout = Duration(seconds: 30);

  /// Shorter readiness watchdog for iframe/WebView-backed sources (YouTube
  /// WebView, Vimeo, WebM): their load can silently stall on a transient
  /// SSL/network blip with no error event, so retry the load sooner instead of
  /// sitting on the loader for 30s. Native sources are already ready when the
  /// timer is armed (initialize() is awaited), so this never fires for them.
  static const Duration _webViewReadyTimeout = Duration(seconds: 15);

  Duration get _readyTimeoutForSource {
    switch (_sourceConfig.videoSourceType) {
      case VideoSourceType.youtube:
      case VideoSourceType.vimeo:
      case VideoSourceType.network:
        return _webViewReadyTimeout;
      case VideoSourceType.asset:
      case VideoSourceType.file:
        return _readyTimeout;
    }
  }

  /// How far playback must advance past [_lastErrorPosition] before the retry
  /// budget is restored. Deliberately generous: a chronically-failing stream
  /// (errors every few seconds) would otherwise play just past a small
  /// threshold, refund the budget, error, recover… forever. Requiring sustained
  /// playback means a single transient blip still refunds (plays on fine) while
  /// a stream that can't hold 10s exhausts the budget and stops at the error
  /// view instead of churning re-inits.
  static const Duration _healthyProgress = Duration(seconds: 10);

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
    _readyTimeoutTimer?.cancel();
    _controller?.removeListener(_onControllerStateChanged);
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

      final initStrategy = await OmniVideoPlayerInitializerFactory.getStrategy(
        _sourceConfig.videoSourceType,
        _sourceConfig,
        widget.configuration,
        widget.callbacks,
        widget.globalController,
      );

      // Load the thumbnail in parallel with controller init so a slow thumbnail
      // fetch (YouTube/Vimeo network image) never delays playback. It's only a
      // loading placeholder, so show it as soon as it's ready. (L2)
      unawaited(
        _loadThumbnail()
            .then((thumb) {
              // Set it whenever it resolves (not only while still loading): for
              // WebView sources init finishes before the network thumbnail
              // arrives, so gating on _isLoading dropped it entirely.
              if (mounted && thumb != null && _thumbnail == null) {
                setState(() => _thumbnail = thumb);
              }
            })
            // The thumbnail is a best-effort placeholder: a fetch failure must
            // not surface as an unhandled async error (it used to be inside the
            // init try/catch).
            .catchError((_) {}),
      );

      _controller = await initStrategy.initialize();
      if (!mounted) return;

      if (_controller != null) {
        _controller!.addListener(_onControllerStateChanged);
        _startReadyTimeout(_controller!);
        if (widget
            .configuration
            .videoSourceConfiguration
            .autoFullScreenAtStart) {
          _controller!.switchFullScreenMode(
            context,
            pageBuilder: (context) => OmniVideoPlayerTheme(
              data: widget.configuration.playerTheme,
              child: OmniVideoPlayerFullscreen(
                controller: _controller!,
                configuration: widget.configuration,
                callbacks: widget.callbacks,
              ),
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Video initialization error: $e\n$st');

      // Check for hardware decoder memory exhaustion (common on Android)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('no_memory') ||
          errorStr.contains('codec') ||
          errorStr.contains('0xfffffff4')) {
        debugPrint(
          'OmniVideoPlayer: Potential hardware decoder exhaustion detected. Attempting to release all resources...',
        );
        await widget.globalController?.releaseAllResources();

        // Retry after cleanup on its own budget (see [_decoderRetryCount]).
        if (_decoderRetryCount < _maxDecoderRetries) {
          _decoderRetryCount++;
          debugPrint(
            'OmniVideoPlayer: Retrying initialization after cleanup...',
          );
          return _initializePlayer();
        }
      }

      _hasError = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ⏱️ FAILSAFE: mark as error if controller not ready within timeout
  void _startReadyTimeout(OmniPlaybackController controller) {
    _readyTimeoutTimer?.cancel();
    _readyTimeoutTimer = Timer(_readyTimeoutForSource, () {
      // Only refresh a *truly* stuck load. If playback already advanced, the
      // player is working even when `isReady` lags (e.g. a WebView whose
      // getDuration is slow to resolve) — recreating it would kill a playing
      // video, so leave it be.
      if (mounted &&
          !controller.isReady &&
          controller.currentPosition <= Duration.zero) {
        refresh();
      }
    });
  }

  // ♻️ PLAYBACK-ERROR RECOVERY
  /// Reacts to the controller flagging `hasError` *after* a successful init
  /// (e.g. a source/range error during a seek). The init-time [refresh] retry
  /// never covered this case, so the error latched and the player was stuck on
  /// the error view forever. Here we re-initialize at the last position so
  /// playback resumes where it failed, bounded by [_maxRetries].
  void _onControllerStateChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || controller.isDisposed) return;

    // Ready → cancel the failsafe timeout so it can't refresh a healthy player. (A5)
    if (controller.isReady) _readyTimeoutTimer?.cancel();

    // Bug 7 (timer-free): restore the retry budgets only once playback has
    // advanced past where it last failed — real proof the source recovered,
    // driven by the controller's own notifications (no polling timer). A server
    // that fails every seek re-inits at the error position and never advances,
    // so the budget stays spent and [_maxRetries] still bounds the loop.
    if (controller.isReady &&
        !controller.hasError &&
        !_recovering &&
        (_errorRetryCount != 0 || _decoderRetryCount != 0) &&
        controller.currentPosition > _lastErrorPosition + _healthyProgress) {
      _errorRetryCount = 0;
      _decoderRetryCount = 0;
    }

    if (_isLoading || _hasError || _recovering || !controller.hasError) return;
    _recoverFromPlaybackError(controller);
  }

  Future<void> _recoverFromPlaybackError(
    OmniPlaybackController controller,
  ) async {
    _recovering = true;
    _lastErrorPosition = controller.currentPosition;
    // Resume where playback failed; falls back to Duration.zero if unknown.
    _sourceConfig = _sourceConfig.copyWith(
      initialPosition: controller.currentPosition,
    );
    await refresh();
    _recovering = false;
  }

  // 📴 OFF-VIEW RELEASE
  /// Frees the native decoder/heap when the player scrolls fully out of view.
  /// Nulling the controller unmounts the player subtree, whose
  /// [OmniVideoPlayerView.dispose] disposes and unregisters it. The player
  /// re-initializes at the same position when it returns on screen (see
  /// [build]/[_reinitAfterOffView]) — this path never touches the error budget.
  void releaseForOffView() {
    if (!mounted || _isLoading || _recovering || _releasedOffView) return;
    final controller = _controller;
    if (controller == null || controller.isDisposed) return;
    // Resume where it left off when the player comes back on screen.
    _sourceConfig = _sourceConfig.copyWith(
      initialPosition: controller.currentPosition,
    );
    setState(() {
      controller.removeListener(_onControllerStateChanged);
      _controller = null;
      _releasedOffView = true;
    });
  }

  Future<void> _reinitAfterOffView() async {
    if (!mounted || !_releasedOffView) return;
    setState(() {
      _releasedOffView = false;
      _resetState();
    });
    await _initializePlayer();
  }

  @override
  void dispose() {
    _readyTimeoutTimer?.cancel();
    _controller?.removeListener(_onControllerStateChanged);
    super.dispose();
  }

  // 🎨 UI BUILD
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OmniVideoPlayerTheme.of(context)!;
    final aspectRatio = _calculateAspectRatio();

    if (_isLoading) return _buildLoadingView(theme, aspectRatio);

    // Released because scrolled off-screen: show the lightweight loading
    // placeholder (not the error view) and re-initialize on return. Its own
    // path so off-view cycles never consume the error retry budget.
    if (_releasedOffView) {
      return VisibilityDetector(
        key: Key('video_offview_${_sourceConfig.hashCode}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.1 && _releasedOffView && !_isLoading) {
            _reinitAfterOffView();
          }
        },
        child: _buildLoadingView(theme, aspectRatio),
      );
    }

    // Se il controller è nullo o è stato distrutto (es. dal global release),
    // usiamo VisibilityDetector per reinizializzare quando riappare a schermo.
    if (_hasError || _controller == null || _controller!.isDisposed) {
      return VisibilityDetector(
        key: Key('video_visibility_retry_${_sourceConfig.hashCode}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.1 &&
              !_isLoading &&
              (_controller == null || _controller!.isDisposed)) {
            debugPrint(
              'OmniVideoPlayer: Re-initializing disposed/error player on visibility',
            );
            refresh();
          }
        },
        child: _buildErrorView(theme),
      );
    }

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
