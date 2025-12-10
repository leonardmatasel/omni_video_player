import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';

import '../controllers/video_playback_controller.dart';

/// A controller that manages synchronized video and optional audio playback.
///
/// Supports features like global player coordination, mute handling,
/// fullscreen transitions, and real-time state updates.
class GenericPlaybackController extends OmniPlaybackController {
  late VideoPlaybackController videoController;
  final VideoPlayerCallbacks callbacks;
  final GlobalKey<OmniVideoPlayerInitializerState> globalKeyPlayer;

  @override
  final File? file;

  VideoSourceType type;
  Map<OmniVideoQuality, Uri>? qualityUrls;
  @override
  OmniVideoQuality? currentVideoQuality;

  @override
  late final Uri? videoUrl;

  @override
  late final String? videoDataSource;

  @override
  late final bool isLive;

  @override
  final VideoSourceType videoSourceType = VideoSourceType.youtube;

  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);

  @override
  final String? videoId = null;

  bool _wasPlayingBeforeSeek = false;
  bool _isFullyVisible = false;

  bool _isSeeking = false;
  bool _isFullScreen = false;
  bool _hasStarted = false;
  bool _isDisposed = false;
  final GlobalPlaybackController? _globalController;
  double _previousVolume = 100;
  bool _isNotifyPending = false;

  GenericPlaybackController._(
    this.videoController,
    this.videoUrl,
    this.videoDataSource,
    this.file,
    this.isLive,
    this._globalController,
    Duration initialPosition,
    double? initialVolume,
    double? initialPlaybackSpeed,
    this.callbacks,
    this.type,
    this.qualityUrls,
    this.currentVideoQuality,
    this.globalKeyPlayer,
  ) {
    if (initialPosition.inSeconds > 0) {
      seekTo(initialPosition, skipHasPlaybackStarted: true);
    }
    if (initialVolume != null) {
      volume = initialVolume * 100;
    }
    if (initialPlaybackSpeed != null) {
      playbackSpeed = initialPlaybackSpeed;
    }
    videoController.addListener(_onControllerUpdate);
  }

  /// Creates and initializes a new [OmniPlaybackController] instance.
  static Future<GenericPlaybackController> create({
    required Uri? videoUrl,
    required String? dataSource,
    required File? file,
    Uri? audioUrl,
    bool isLive = false,
    GlobalPlaybackController? globalController,
    initialPosition = Duration.zero,
    double? initialVolume,
    required double? initialPlaybackSpeed,
    required VideoPlayerCallbacks callbacks,
    required VideoSourceType type,
    Map<OmniVideoQuality, Uri>? qualityUrls,
    OmniVideoQuality? currentVideoQuality,
    required GlobalKey<OmniVideoPlayerInitializerState> globalKeyPlayer,
  }) async {
    final videoController =
        (type == VideoSourceType.asset && dataSource != null)
        ? VideoPlaybackController.asset(dataSource)
        : (type == VideoSourceType.file && file != null)
        ? VideoPlaybackController.file(file)
        : VideoPlaybackController.uri(videoUrl!.toString(), isLive: isLive);

    if (audioUrl != null) {
      await videoController.player.setAudioTrack(
        AudioTrack.uri(audioUrl.toString()),
      );
    }

    return GenericPlaybackController._(
      videoController,
      videoUrl,
      dataSource,
      file,
      isLive,
      globalController,
      initialPosition,
      initialVolume,
      initialPlaybackSpeed,
      callbacks,
      type,
      qualityUrls,
      currentVideoQuality,
      globalKeyPlayer,
    );
  }

  @override
  Future<void> switchQuality(OmniVideoQuality newQuality) async {
    if (currentVideoQuality == null ||
        qualityUrls == null ||
        newQuality == currentVideoQuality) {
      return;
    }

    final newUrl = qualityUrls![newQuality];
    if (newUrl == null) return;

    final wasPlaying = isPlaying;
    final currentPos = currentPosition;

    await pause(useGlobalController: false);

    isSeeking = true;
    await videoController.player.open(Media(newUrl.toString()), play: false);
    await Future.delayed(const Duration(seconds: 2));
    await seekTo(currentPos);

    currentVideoQuality = newQuality;
    isSeeking = false;
    if (wasPlaying) {
      await play(useGlobalController: false);
    }

    notifyListeners();
  }

  void _onControllerUpdate() {
    if (_isNotifyPending) return;
    _isNotifyPending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _isNotifyPending = false;
      notifyListeners();
    });
  }

  @override
  bool get wasPlayingBeforeSeek => _wasPlayingBeforeSeek;

  @override
  set wasPlayingBeforeSeek(bool value) {
    if (isSeeking) {
      return;
    }
    _wasPlayingBeforeSeek = value;
    notifyListeners();
  }

  /// Returns true if both video and audio (if present) are initialized.
  @override
  bool get isReady => videoController.isReady;

  /// Returns true if both video and audio (if present) are currently playing.
  @override
  bool get isPlaying => videoController.isPlaying;

  /// Returns true if the video is buffering.
  @override
  bool get isBuffering => videoController.isBuffering;

  /// Returns true if an error occurred during video playback.
  @override
  bool get hasError => videoController.hasError;

  /// Returns true if the video is muted.
  @override
  bool get isMuted => videoController.volume == 0;

  /// Whether a seek operation is currently in progress.
  @override
  bool get isSeeking => _isSeeking || videoController.isSeeking;

  /// Whether playback has started at least once.
  @override
  bool get hasStarted => _hasStarted;

  @override
  set isSeeking(bool value) {
    _isSeeking = value;
    if (!value) callbacks.onSeekEnd?.call(currentPosition);
    notifyListeners();
  }

  /// Whether the video is currently in fullscreen mode.
  @override
  bool get isFullScreen => _isFullScreen;

  /// Returns the current playback position of the video.
  @override
  Duration get currentPosition => videoController.currentPosition;

  /// Returns true if the video playback has reached the end.
  @override
  bool get isFinished =>
      (currentPosition.inSeconds >= duration.inSeconds - 1 &&
          duration.inSeconds != 1) &&
      !isLive;

  /// Returns the total duration of the video.
  @override
  Duration get duration => videoController.duration == Duration.zero
      ? Duration(seconds: 1)
      : videoController.duration;

  /// Returns the rotation correction to be applied to the video.
  @override
  int get rotationCorrection => videoController.rotationCorrection;

  /// Returns the resolution size of the video.
  @override
  Size get size => videoController.size;

  /// Returns the buffered ranges of the video.
  @override
  Duration get buffer => videoController.buffer;

  /// Starts or resumes playback.
  ///
  /// If [useGlobalController] is true and a global controller is provided,
  /// playback requests will be routed through it.
  @override
  Future<void> play({bool useGlobalController = true}) async {
    _hasStarted = true;
    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPlay(this);
    } else {
      await videoController.play();
    }
  }

  /// Pauses playback.
  ///
  /// If [useGlobalController] is true and a global controller is provided,
  /// pause requests will be routed through it.
  @override
  Future<void> pause({bool useGlobalController = true}) async {
    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPause();
    } else {
      await videoController.pause();
    }
  }

  /// Restarts playback from the beginning.
  @override
  Future<void> replay({bool useGlobalController = true}) async {
    await Future.wait([
      pause(useGlobalController: useGlobalController),
      seekTo(Duration.zero),
      play(useGlobalController: useGlobalController),
    ]);
  }

  /// Returns the current volume (0.0 to 1.0).
  @override
  double get volume => videoController.volume / 100;

  /// Sets the volume for both video and audio (if present).
  @override
  set volume(double value) {
    videoController.player.setVolume(value * 100);
  }

  /// Toggles mute on or off based on current state.
  @override
  void toggleMute() => isMuted ? unMute() : mute();

  /// Mutes the playback
  @override
  void mute() {
    _previousVolume = videoController.volume;
    videoController.player.setVolume(0);
    _globalController?.setCurrentVolume(0);
  }

  /// Restores the previous volume level.
  @override
  void unMute() {
    double tmpVolume = _previousVolume == 0 ? 100 : _previousVolume;
    videoController.player.setVolume(tmpVolume);
    _globalController?.setCurrentVolume(tmpVolume / 100);
  }

  /// Seeks playback to a specific [position] in the video.
  ///
  /// Throws [ArgumentError] if the position exceeds the video duration.
  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    if (position <= duration) {
      if (isFinished) {
        await pause();
      } else {
        videoController.seekingPosition = position;
      }

      if (callbacks.onSeekRequest != null &&
          !callbacks.onSeekRequest!(position)) {
        isSeeking = false;
        return;
      }

      wasPlayingBeforeSeek = isPlaying;
      if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
        _hasStarted = true;
      }

      await videoController.player.seek(position);

      if (wasPlayingBeforeSeek && !isFinished) {
        await videoController.play();
      }
    } else {
      throw ArgumentError('Seek position exceeds duration');
    }
    isSeeking = false;
  }

  /// Opens or closes the fullscreen playback mode.
  ///
  /// Requires a [BuildContext], a [pageBuilder] to render the fullscreen view,
  /// and an optional [onToggle] callback to react to fullscreen state changes.
  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext)? pageBuilder,
    Widget? playerAlreadyBuilt,
    void Function(bool)? onToggle,
  }) async {
    if (_isFullScreen) {
      Navigator.of(context).pop();
    } else {
      _isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) {
            return pageBuilder!(context);
          },
          transitionsBuilder: (_, animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      _isFullScreen = false;
      notifyListeners();
      onToggle?.call(false);
    }
  }

  /// Disposes the controller and its resources.
  @override
  Future<void> dispose() async {
    _isDisposed = true;

    videoController.removeListener(_onControllerUpdate);
    // If this controller is still playing according to the global manager,
    // ensure we pause it before disposing.
    if (_globalController?.currentVideoPlaying == this) {
      _globalController?.requestPause();
    }
    await videoController.dispose();
    super.dispose();
  }

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => qualityUrls;

  @override
  List<OmniVideoQuality>? get availableVideoQualities =>
      qualityUrls?.keys.toList();

  @override
  double get playbackSpeed => videoController.playbackSpeed;

  @override
  set playbackSpeed(double speed) {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }

    videoController.player.setRate(speed);
    notifyListeners();
  }

  @override
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration) {
    globalKeyPlayer.currentState?.refresh(
      videoSourceConfiguration: videoSourceConfiguration,
    );
  }

  @override
  bool get isFullyVisible => _isFullyVisible;

  @override
  set isFullyVisible(bool value) {
    _isFullyVisible = value;
    notifyListeners();
  }
}
