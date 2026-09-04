import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:omni_video_player/omni_video_player.dart';
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
  final Map<String, String>? httpHeaders;
  final bool mixWithOthers;

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

  /// Monotonic token so a newer [seekTo] supersedes an older in-flight one
  /// instead of their async steps interleaving into incoherent state. (B1)
  int _seekGeneration = 0;

  /// Guards against re-entrant [switchQuality] while a swap is in flight. (B3)
  bool _swappingController = false;
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
    this.httpHeaders,
    this.mixWithOthers,
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
    _globalController?.registerController(this);
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
    Map<String, String>? httpHeaders,
    bool mixWithOthers = false,
  }) async {
    final videoController =
        (type == VideoSourceType.asset && dataSource != null)
        ? VideoPlaybackController.asset(dataSource)
        : (type == VideoSourceType.file && file != null)
        ? VideoPlaybackController.file(file)
        : VideoPlaybackController.uri(
            videoUrl!,
            isLive: isLive,
            mixWithOthers: mixWithOthers,
            httpHeaders: httpHeaders ?? const <String, String>{},
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
      httpHeaders,
      mixWithOthers,
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

    // Guard against a re-entrant switch racing on [videoController]. (B3)
    if (_swappingController) return;
    _swappingController = true;
    try {
      final wasPlaying = isPlaying;
      final currentPos = currentPosition;
      // Preserve the CURRENT volume/mute across the swap. Using _previousVolume
      // (the unmute-restore value) left the new videoController's volume — and
      // therefore isMuted / the mute button — out of sync with the actual sound
      // (the audioController isn't swapped).
      final currentVolume = videoController.value.volume;

      await pause(useGlobalController: false);

      if (!await _swapVideoController(newUrl, volume: currentVolume)) return;
      currentVideoQuality = newQuality;

      await seekTo(currentPos);
      if (wasPlaying) await play(useGlobalController: false);

      notifyListeners();
    } finally {
      _swappingController = false;
    }
  }

  /// Replaces the native player with a fresh one on the same [url], at zero.
  ///
  /// Returns false if this controller was disposed meanwhile. The caller holds
  /// the [_swappingController] lock and decides position and playback.
  Future<bool> _swapVideoController(Uri url, {required double volume}) async {
    final newController = VideoPlaybackController.uri(
      url,
      isLive: isLive,
      mixWithOthers: mixWithOthers,
      httpHeaders: httpHeaders ?? const <String, String>{},
    );
    await newController.initialize();
    if (_isDisposed) {
      await newController.dispose();

      return false;
    }

    // Swap atomically: detach old, point [videoController] at the new one,
    // then attach — so [_onControllerUpdate] never reads a half-swapped or
    // already-disposed controller. (B3)
    final old = videoController;
    old.removeListener(_onControllerUpdate);
    videoController = newController;
    videoController.addListener(_onControllerUpdate);

    sharedPlayerNotifier.value = Hero(
      tag: globalKeyPlayer,
      child: VideoPlayer(key: GlobalKey(), newController),
    );

    videoController.setVolume(volume);
    await old.dispose();

    return true;
  }

  /// Whether a replay rebuilds the player instead of seeking back to zero.
  ///
  /// On Android the flush behind a seek can take tens of seconds on a heavy
  /// stream (4K HDR HEVC); a fresh player starts over with no flush at all.
  static bool get _replayRebuildsPlayer =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _onControllerUpdate() {
    if (_isDisposed) return;

    if (_isReplaying && videoController.value.isPlaying) _isReplaying = false;

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
    // Latest-wins: a newer seekTo supersedes this one so their async steps
    // can't interleave into an incoherent pause/resume. (B1)
    final int seekGen = ++_seekGeneration;
    bool superseded() => _isDisposed || seekGen != _seekGeneration;

    // Clamp instead of bailing out: an early `return` here left [isSeeking]
    // stuck at true forever (controls frozen, no resume) whenever the target
    // landed past the end — e.g. dragging to the very end, or a recovery seek.
    if (duration > Duration.zero && position > duration) {
      position = duration;
    }

    if (callbacks.onSeekRequest != null &&
        !callbacks.onSeekRequest!(position)) {
      isSeeking = false;
      return;
    }

    if (!_isSeeking) {
      wasPlayingBeforeSeek = isPlaying;
    }
    isSeeking = true;
    _videoStuckCounter = 0;
    _lastVideoPosition = Duration.zero;

    if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
      _hasStarted = true;
    }

    // 1. STOP TOTALE
    await Future.wait([
      videoController.pause(),
      if (audioController != null) audioController!.pause(),
    ]);
    if (superseded()) return;

    // 2. SEEK VIDEO
    await videoController.seekTo(position);
    if (superseded()) return;

    // 3. Wait for the seek to actually land (condition, not a fixed delay), so
    //    audio aligns to the real landed position. (A1)
    await _waitUntil(
      () =>
          (videoController.value.position - position).abs() <=
              const Duration(milliseconds: 400) &&
          !videoController.isActuallyBuffering,
      timeout: const Duration(milliseconds: 500),
      step: const Duration(milliseconds: 20),
    );
    if (superseded()) return;
    final Duration actualVideoPosition = videoController.value.position;
    _lastVideoPosition = actualVideoPosition;

    // 4. SEEK AUDIO to the real landed position (the resume path waits for the
    //    audio buffer, so no fixed delay is needed here).
    if (audioController != null) {
      await audioController!.seekTo(actualVideoPosition);
      if (superseded()) return;
    }

    callbacks.onSeekEnd?.call(actualVideoPosition);

    // 5. RESUME through play() so it honors the single-active-player rule via
    //    the global controller instead of racing it. (B2)
    if (superseded()) return;
    if (wasPlayingBeforeSeek && !isFinished) {
      await play();
    } else {
      isSeeking = false;
      notifyListeners();
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

      // If the audio didn't start, wait on the condition (not a fixed delay)
      // and retry once while the video is actually playing. (A3)
      if (!audioController!.value.isPlaying) {
        await _waitUntil(
          () =>
              audioController!.value.isPlaying ||
              !videoController.value.isPlaying,
          timeout: const Duration(milliseconds: 400),
          step: const Duration(milliseconds: 30),
        );
        if (videoController.value.isPlaying &&
            !audioController!.value.isPlaying) {
          await audioController!.play();
        }
      }
    }

    isSeeking = false;
    notifyListeners();
    _startProgressTimer();
  }

  /// Polls [condition] every [step] until it holds or [timeout] elapses. Used
  /// to replace fixed `Future.delayed` waits with condition-based ones so state
  /// transitions don't depend on a guessed duration. (A1/A3)
  Future<void> _waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration step = const Duration(milliseconds: 50),
  }) async {
    var elapsed = Duration.zero;
    while (elapsed < timeout && !condition() && !_isDisposed) {
      await Future.delayed(step);
      elapsed += step;
    }
  }

  /// How long a resume waits for the buffer before starting anyway.
  ///
  /// Deliberately short: [isSeeking] stays true for all of it, so anything
  /// reading that flag sees a seek that has long landed. ExoPlayer buffers on
  /// its own regardless.
  static const _bufferWait = Duration(seconds: 2);

  Future<void> _waitForBuffer(VideoPlayerController controller) => _waitUntil(
    () => !controller.value.isBuffering && controller.value.isInitialized,
    timeout: _bufferWait,
    step: const Duration(milliseconds: 100),
  );

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
    // User intent = playing. This is the source of truth for whether a seek
    // should resume, instead of the momentary (and buffering-unreliable)
    // [isPlaying] read taken at drag start.
    _wasPlayingBeforeSeek = true;

    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPlay(this);
    }

    await _resumeSynchronized();
  }

  @override
  Future<void> pause({bool useGlobalController = true}) async {
    // User intent = paused (see [play]).
    _wasPlayingBeforeSeek = false;

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

  bool _isReplaying = false;

  @override
  bool get isReplaying => _isReplaying;

  @override
  Future<void> replay({bool useGlobalController = true}) async {
    _isReplaying = true;
    notifyListeners();

    await pause(useGlobalController: useGlobalController);

    final url = videoUrl;
    if (_replayRebuildsPlayer && url != null && !_swappingController) {
      _swappingController = true;
      // Rebuilding means an initialize: without this the UI sits on the
      // replay button, frozen, until playback comes back.
      isSeeking = true;
      try {
        if (!await _swapVideoController(
          url,
          volume: videoController.value.volume,
        )) {
          // The rebuild failed: close the window here, or it stays open
          // forever on a player that will never resume.
          _isReplaying = false;

          return;
        }
      } finally {
        _swappingController = false;
        isSeeking = false;
      }
    } else {
      await seekTo(Duration.zero);
    }

    await play(useGlobalController: useGlobalController);

    // If the play already landed the window closes here; otherwise
    // [_onControllerUpdate] closes it as soon as the platform reports it.
    if (isPlaying) {
      _isReplaying = false;
      notifyListeners();
    }
  }

  @override
  bool get isDisposed => _isDisposed;

  @override
  Future<void> dispose() async {
    _isReplaying = false;
    _globalController?.unregisterController(this);
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

  /// Swallows notifications once disposed. Async tails (e.g. the resume after
  /// [switchFullScreenMode]'s awaited route, or a pending seek) can run after
  /// the controller is disposed — e.g. advancing a playlist while fullscreen is
  /// open disposes this controller, and the route's `notifyListeners()` then
  /// hit a disposed ChangeNotifier and threw ("used after being disposed").
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
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
    if (!_isDisposed) {
      notifyListeners();
    }
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

  /// Returns the total duration of the video.
  @override
  Duration get duration => _duration;

  set duration(Duration value) {
    if (isDisposed) return;
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
    if (isDisposed) return;
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
    _globalController?.setCurrentVolume(0, source: this);
  }

  /// Restores the previous volume level.
  @override
  void unMute() {
    double tmpVolume = _previousVolume == 0 ? 1 : _previousVolume;
    videoController.setVolume(tmpVolume);
    audioController?.setVolume(tmpVolume);
    _globalController?.setCurrentVolume(tmpVolume, source: this);
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

      // The controller may have been disposed while fullscreen was open (e.g. a
      // playlist advanced to the next video); don't touch its state then.
      if (_isDisposed) return;
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
