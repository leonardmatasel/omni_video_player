import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:video_player/video_player.dart';

import '../controllers/audio_playback_controller.dart';
import '../controllers/video_playback_controller.dart';

/// A controller that manages synchronized video and optional audio playback.
///
/// Supports features like global player coordination, mute handling,
/// fullscreen transitions, and real-time state updates.
class GenericPlaybackController extends OmniPlaybackController {
  late VideoPlaybackController videoController;
  late AudioPlaybackController? audioController;

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
  double _previousVolume = 1.0;
  bool _isNotifyPending = false;

  Duration _duration = Duration.zero;

  GenericPlaybackController._(
    this.videoController,
    this.audioController,
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
    duration = videoController.value.duration;

    if (initialPosition.inSeconds > 0) {
      seekTo(initialPosition, skipHasPlaybackStarted: true);
    }
    if (initialVolume != null) {
      volume = initialVolume;
    }
    if (initialPlaybackSpeed != null) {
      playbackSpeed = initialPlaybackSpeed;
    }
    videoController.addListener(_onControllerUpdate);
    audioController?.addListener(_onControllerUpdate);
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
        : VideoPlaybackController.uri(
            videoUrl!,
            isLive: isLive,
            mixWithOthers: false,
          );
    await videoController.initialize().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException(
          'videoController initialization timed out after 30 seconds',
        );
      },
    );

    AudioPlaybackController? audioController;
    if (audioUrl != null) {
      audioController = AudioPlaybackController.uri(
        audioUrl,
        isLive: isLive,
        mixWithOthers: true,
      );
      await audioController.initialize();
    }

    return GenericPlaybackController._(
      videoController,
      audioController,
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

    final newController = VideoPlaybackController.uri(newUrl, isLive: isLive);
    await newController.initialize();

    videoController.removeListener(_onControllerUpdate);

    newController.addListener(_onControllerUpdate);

    currentVideoQuality = newQuality;

    sharedPlayerNotifier.value = Hero(
      tag: globalKeyPlayer,
      child: VideoPlayer(key: GlobalKey(), newController),
    );

    await videoController.dispose();

    videoController = newController;
    await seekTo(currentPos);

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
  bool get isReady =>
      videoController.value.isInitialized &&
      (audioController?.value.isInitialized ?? true);

  /// Returns true if both video and audio (if present) are currently playing.
  @override
  bool get isPlaying =>
      videoController.value.isPlaying &&
      (audioController?.value.isPlaying ?? true);

  /// Returns true if the video is buffering.
  @override
  bool get isBuffering => videoController.isActuallyBuffering;

  /// Returns true if an error occurred during video playback.
  @override
  bool get hasError => videoController.value.hasError;

  /// Returns true if the video is muted.
  @override
  bool get isMuted => videoController.value.volume == 0;

  /// Whether a seek operation is currently in progress.
  @override
  bool get isSeeking => _isSeeking;

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
  Duration get currentPosition => videoController.value.position;

  /// Returns true if the video playback has reached the end.
  @override
  bool get isFinished =>
      (currentPosition.inSeconds >= duration.inSeconds) && !isLive;

  /// Returns the total duration of the video.
  @override
  Duration get duration => _duration;

  set duration(Duration value) {
    _duration = value;
    notifyListeners();
  }

  /// Returns the rotation correction to be applied to the video.
  @override
  int get rotationCorrection => videoController.value.rotationCorrection;

  /// Returns the resolution size of the video.
  @override
  Size get size => videoController.value.size;

  /// Returns the buffered ranges of the video.
  @override
  List<DurationRange> get buffered => videoController.value.buffered;

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
      await Future.wait([
        if (audioController != null) audioController!.play(),
        videoController.play(),
      ]);
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
      await Future.wait([
        if (audioController != null) audioController!.pause(),
        videoController.pause(),
      ]);
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
  double get volume => videoController.value.volume;

  /// Sets the volume for both video and audio (if present).
  @override
  set volume(double value) {
    videoController.setVolume(value);
    audioController?.setVolume(value);
  }

  /// Toggles mute on or off based on current state.
  @override
  void toggleMute() => isMuted ? unMute() : mute();

  /// Mutes the playback
  @override
  void mute() {
    _previousVolume = videoController.value.volume;
    videoController.setVolume(0);
    audioController?.setVolume(0);
    _globalController?.setCurrentVolume(0);
  }

  /// Restores the previous volume level.
  @override
  void unMute() {
    double tmpVolume = _previousVolume == 0 ? 1 : _previousVolume;
    videoController.setVolume(tmpVolume);
    audioController?.setVolume(tmpVolume);
    _globalController?.setCurrentVolume(tmpVolume);
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
        pause();
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

      await Future.wait([
        if (audioController != null) audioController!.pause(),
        videoController.pause(),
      ]);

      await Future.wait([
        if (audioController != null) audioController!.seekTo(position),
        videoController.seekTo(position),
      ]);

      // Aspetta che l'audio smetta di fare buffering
      if (audioController != null) {
        while ((audioController!.isActuallyBuffering) ||
            videoController.isActuallyBuffering) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }

      if (wasPlayingBeforeSeek && !isFinished) {
        await Future.wait([
          if (audioController != null) audioController!.play(),
          videoController.play(),
        ]);
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
    super.dispose();
    videoController.removeListener(_onControllerUpdate);
    audioController?.removeListener(_onControllerUpdate);
    // If this controller is still playing according to the global manager,
    // ensure we pause it before disposing.
    if (_globalController?.currentVideoPlaying == this) {
      _globalController?.requestPause();
    }
    await videoController.dispose();
    await audioController?.dispose();
  }

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => qualityUrls;

  @override
  List<OmniVideoQuality>? get availableVideoQualities =>
      qualityUrls?.keys.toList();

  @override
  double get playbackSpeed => videoController.value.playbackSpeed;

  @override
  set playbackSpeed(double speed) {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }

    videoController.setPlaybackSpeed(speed);
    audioController?.setPlaybackSpeed(speed);
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

class VideoAudioPair {
  VideoAudioPair(this.videoController, this.audioController);

  final VideoPlaybackController videoController;
  final AudioPlaybackController? audioController;
}
