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
  Timer? _progressTimer;

  // --- Sync Variables ---
  Duration _lastVideoPosition = Duration.zero;
  int _videoStuckCounter = 0;

  // ---------------------------------------------------------------------------
  // SYNC ENGINE (CORE LOGIC)
  // ---------------------------------------------------------------------------

  void _performSyncCheck() {
    if (audioController == null || isSeeking) {
      _videoStuckCounter = 0;
      return;
    }

    final currentVideoPos = videoController.value.position;
    final currentAudioPos = audioController!.value.position;
    final bool isVideoPlaying = videoController.value.isPlaying;
    final bool isAudioPlaying = audioController!.value.isPlaying;
    final bool isAudioBuffering = audioController!.value.isBuffering;

    // Otteniamo la velocità attuale
    final double currentSpeed = videoController.value.playbackSpeed;

    // --- FIX 1: Safety Check Video Fermo ---
    if (!isVideoPlaying) {
      if (isAudioPlaying) {
        audioController!.pause();
      }
      _videoStuckCounter = 0;
      return;
    }

    // --- 1. AUDIO BUFFERING GUARD ---
    if (isAudioBuffering) {
      videoController.pause();
      return;
    }

    // --- 2. SAFETY NET (Kickstart) ---
    if (!videoController.isActuallyBuffering &&
        !isAudioPlaying &&
        !isAudioBuffering &&
        !isFinished) {
      if (currentAudioPos < (duration - const Duration(milliseconds: 500))) {
        audioController!.play();
      }
    }

    // --- 3. RILEVAMENTO STALLO VIDEO (FIXED per 2x) ---
    if (!videoController.isActuallyBuffering &&
        currentVideoPos == _lastVideoPosition) {
      _videoStuckCounter++;

      // FIX: A velocità alta (2x), il video può saltare frame o aggiornare la posizione
      // meno frequentemente. Aumentiamo la soglia di tolleranza.
      // 1x -> soglia 2 tick (400ms)
      // 2x -> soglia 4 tick (800ms)
      int stuckThreshold = (2 * currentSpeed).ceil();

      if (_videoStuckCounter > stuckThreshold && isAudioPlaying) {
        audioController!.pause();
      }
    } else {
      _videoStuckCounter = 0;
      _lastVideoPosition = currentVideoPos;
    }

    // --- 4. CONTROLLO DERIVA (Drift) (FIXED per 2x) ---
    if (isAudioPlaying) {
      final int diff =
          currentAudioPos.inMilliseconds - currentVideoPos.inMilliseconds;

      // FIX: Calcoliamo una tolleranza dinamica.
      // A 2x, la posizione video riportata da Flutter è spesso in ritardo di
      // diverse centinaia di ms rispetto al render reale.
      // Base: 250ms. Se speed è 2.0 -> tolleranza diventa 500ms.
      final int maxAllowedDrift = (250 * currentSpeed).toInt();

      // Audio troppo avanti -> Pausa
      if (diff > maxAllowedDrift) {
        // print("SYNC: Drift detected ($diff ms > $maxAllowedDrift ms) -> Pausing Audio");
        audioController!.pause();
      }
      // Audio troppo indietro (< -500ms) -> Seek
      // Aumentiamo leggermente anche questo margine per evitare seek continui
      else if (diff < (-500 * currentSpeed)) {
        audioController!.seekTo(currentVideoPos);
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      // Eseguiamo il check se il VIDEO è in play, oppure se stavamo aspettando buffering
      if ((videoController.value.isPlaying || _wasPlayingBeforeSeek) &&
          !isSeeking) {
        _performSyncCheck();
        notifyListeners();
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCTORS
  // ---------------------------------------------------------------------------

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
      setPlaybackSpeed(initialPlaybackSpeed);
    }
    videoController.addListener(_onControllerUpdate);
    audioController?.addListener(_onControllerUpdate);
  }

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
    videoController.setVolume(_previousVolume);

    await seekTo(currentPos);

    if (wasPlaying) {
      await play(useGlobalController: false);
    }

    notifyListeners();
  }

  void _onControllerUpdate() {
    if (_isDisposed) return;

    if (duration != videoController.value.duration) {
      duration = videoController.value.duration;
    }

    // Gestione Macro-Buffering (Video)
    if (audioController != null && _hasStarted && !isSeeking) {
      final bool videoBuffering = videoController.isActuallyBuffering;

      if (videoBuffering && audioController!.value.isPlaying) {
        audioController!.pause();
      }

      // Controllo inverso: se AUDIO sta bufferizzando, metti in pausa VIDEO
      if (audioController!.value.isBuffering &&
          videoController.value.isPlaying) {
        videoController.pause();
      }
    }

    if (_isNotifyPending) return;
    _isNotifyPending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _isNotifyPending = false;
      notifyListeners();
    });
  }

  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    if (position > duration) return;

    isSeeking = true;
    _videoStuckCounter = 0;
    _lastVideoPosition = Duration.zero;

    if (!_isSeeking) {
      wasPlayingBeforeSeek = isPlaying;
    }

    if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
      _hasStarted = true;
    }

    // 1. STOP TOTALE
    await Future.wait([
      videoController.pause(),
      if (audioController != null) audioController!.pause(),
    ]);

    // 2. SEEK VIDEO
    await videoController.seekTo(position);

    // 3. ATTESA STABILIZZAZIONE VIDEO
    await Future.delayed(const Duration(milliseconds: 100));
    final Duration actualVideoPosition = videoController.value.position;
    _lastVideoPosition = actualVideoPosition;

    // 4. SEEK AUDIO
    if (audioController != null) {
      await audioController!.seekTo(actualVideoPosition);
      // Wait per i seek lunghi: diamo tempo all'audio di capire che deve caricare nuovi dati
      await Future.delayed(const Duration(milliseconds: 100));
    }

    callbacks.onSeekEnd?.call(actualVideoPosition);

    // 5. RIPRESA
    if (wasPlayingBeforeSeek && !isFinished) {
      await _resumeSynchronized();
    } else {
      isSeeking = false;
      notifyListeners();
    }

    if (wasPlayingBeforeSeek) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed) isSeeking = false;
      });
    }
  }

  /// Metodo che attende il buffering di ENTRAMBI prima di avviare
  Future<void> _resumeSynchronized() async {
    // 1. Attesa Video Buffering
    if (videoController.isActuallyBuffering) {
      await _waitForBuffer(videoController);
    }

    // 2. Attesa Audio Buffering (CRUCIALE PER SEEK LUNGHI)
    // Se l'audio controller esiste e sta bufferizzando, dobbiamo aspettarlo
    if (audioController != null && audioController!.value.isBuffering) {
      await _waitForAudioBuffer();
    }

    // 3. Avvio Video
    await videoController.play();

    // 4. Avvio Audio con Kickstart
    if (audioController != null) {
      await audioController!.play();

      // Doppio controllo per essere sicuri
      if (!audioController!.value.isPlaying) {
        await Future.delayed(const Duration(milliseconds: 150));
        // Riprova solo se il video sta effettivamente andando
        if (videoController.value.isPlaying) {
          await audioController!.play();
        }
      }
    }

    isSeeking = false;
    notifyListeners();
    _startProgressTimer();
  }

  // Helper per aspettare il video
  Future<void> _waitForBuffer(VideoPlayerController controller) async {
    final int timeoutMs = 10000;
    final int stepMs = 100;
    int elapsed = 0;

    while (elapsed < timeoutMs) {
      if (!controller.value.isBuffering && controller.value.isInitialized) {
        break;
      }
      await Future.delayed(Duration(milliseconds: stepMs));
      elapsed += stepMs;
    }
  }

  // Helper specifico per aspettare l'audio
  Future<void> _waitForAudioBuffer() async {
    final int timeoutMs = 10000;
    final int stepMs = 100;
    int elapsed = 0;

    while (elapsed < timeoutMs) {
      if (audioController != null &&
          !audioController!.value.isBuffering &&
          audioController!.value.isInitialized) {
        break;
      }
      await Future.delayed(Duration(milliseconds: stepMs));
      elapsed += stepMs;
    }
  }

  @override
  Future<void> play({bool useGlobalController = true}) async {
    _hasStarted = true;

    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPlay(this);
    }

    await _resumeSynchronized();
  }

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
    _stopProgressTimer();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }

    // 1. Memorizziamo se il video stava suonando prima del cambio
    final bool wasPlaying = isPlaying;

    // 2. Aggiungiamo 'await' per garantire che il comando arrivi alla piattaforma
    await videoController.setPlaybackSpeed(speed);
    if (audioController != null) {
      await audioController!.setPlaybackSpeed(speed);
    }

    // 3. Safety Check: Se era in play, forziamo il mantenimento dello stato play
    // (Alcune implementazioni native mettono in pausa al cambio velocità)
    if (wasPlaying && !videoController.value.isPlaying) {
      await videoController.play();
    }

    // NOTA: Non serve forzare l'audio qui, il Sync Engine (col fix sopra)
    // o il play() del video lo gestiranno.

    notifyListeners();
  }

  @override
  Future<void> replay({bool useGlobalController = true}) async {
    await Future.wait([
      pause(useGlobalController: useGlobalController),
      seekTo(Duration.zero),
      play(useGlobalController: useGlobalController),
    ]);
  }

  @override
  Future<void> dispose() async {
    _stopProgressTimer();
    _isDisposed = true;
    super.dispose();

    videoController.removeListener(_onControllerUpdate);
    audioController?.removeListener(_onControllerUpdate);

    if (_globalController?.currentVideoPlaying == this) {
      _globalController?.requestPause();
    }

    await videoController.dispose();
    await audioController?.dispose();
  }

  // ---------------------------------------------------------------------------
  // GETTERS & SETTERS
  // ---------------------------------------------------------------------------

  @override
  bool get wasPlayingBeforeSeek => _wasPlayingBeforeSeek;

  @override
  set wasPlayingBeforeSeek(bool value) {
    if (isSeeking) return;
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
  bool get isPlaying => videoController.value.isPlaying;

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

  @override
  double get volume => videoController.value.volume;

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

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => qualityUrls;

  @override
  List<OmniVideoQuality>? get availableVideoQualities =>
      qualityUrls?.keys.toList();

  @override
  double get playbackSpeed => videoController.value.playbackSpeed;

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
