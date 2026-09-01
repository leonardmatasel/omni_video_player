import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';

/// Manages global video-player behavior using Provider.
/// Ensures a single active playback, consistent audio, and wakelock control.
class GlobalPlaybackController extends ChangeNotifier {
  static final GlobalPlaybackController _instance =
      GlobalPlaybackController._internal();

  factory GlobalPlaybackController() => _instance;

  final Lock _lock = Lock();
  double _previousVolumeValue = 1.0;

  OmniPlaybackController? _currentVideoPlaying;
  double _currentVolume = 1.0;

  /// A list of all active controllers to manage resources globally.
  final List<OmniPlaybackController> _allControllers = [];

  OmniPlaybackController? get currentVideoPlaying => _currentVideoPlaying;
  double get currentVolume => _currentVolume;
  bool get isMute => _currentVolume == 0;

  GlobalPlaybackController._internal() {
    _initVolumeListener();
  }

  /// Registers a controller to be tracked globally.
  ///
  /// Also subscribes [_syncWakelock] to the controller's own
  /// `notifyListeners()`, which is what makes the wakelock react to state the
  /// global controller doesn't drive itself — a fullscreen toggle, or
  /// `isPlaying` flipping true later once a WebView backend's async `play()`
  /// call actually lands.
  void registerController(OmniPlaybackController controller) {
    if (!_allControllers.contains(controller)) {
      _allControllers.add(controller);
      controller.addListener(_syncWakelock);
    }
  }

  /// Unregisters a controller from global tracking.
  ///
  /// Re-evaluates the wakelock on the way out: a player is normally disposed
  /// directly by its widget, without passing through [requestPause], so this is
  /// the only chance to release a wakelock the departing player was the last one
  /// to deserve.
  void unregisterController(OmniPlaybackController controller) {
    controller.removeListener(_syncWakelock);
    _allControllers.remove(controller);
    _syncWakelock();
  }

  /// Releases all resources by disposing of all tracked controllers.
  /// Useful for handling "NO_MEMORY" or "CodecException" errors on Android.
  Future<void> releaseAllResources() async {
    await _lock.synchronized(() async {
      final controllersToDispose = List<OmniPlaybackController>.from(
        _allControllers,
      );
      for (final controller in controllersToDispose) {
        try {
          controller.dispose();
        } catch (e) {
          debugPrint('Error during forced dispose: $e');
        }
      }
      _allControllers.clear();
      _currentVideoPlaying = null;
      await _syncWakelock();
      notifyListeners();
    });
  }

  Future<void> _initVolumeListener() async {
    _previousVolumeValue = await VolumeController.instance.getVolume();

    VolumeController.instance.addListener((volume) {
      if (volume == 0) {
        setCurrentVolume(0);
      } else if (volume > _previousVolumeValue) {
        setCurrentVolume(1);
      }
      _previousVolumeValue = volume;
    });
  }

  @override
  void dispose() {
    VolumeController.instance.removeListener();
    super.dispose();
  }

  /// Records the shared volume level, and — when [source] is given — lets that
  /// player enter or leave exclusivity according to its new volume.
  ///
  /// The exclusivity update runs unawaited, because this method is `void` and
  /// its callers are the synchronous `mute()`/`unMute()`. The cost is that while
  /// another operation holds the lock, [currentVideoPlaying] settles a moment
  /// after `mute()` returns rather than immediately.
  void setCurrentVolume(double volume, {OmniPlaybackController? source}) {
    _currentVolume = volume;
    notifyListeners();
    if (source != null) {
      handleVolumeChanged(source).catchError(
        (e) =>
            debugPrint('Failed to update exclusivity after volume change: $e'),
      );
    }
  }

  /// Plays a controller, pausing the current **audible** player first.
  ///
  /// Exclusivity protects the device's audio, so it applies only among audible
  /// players: a muted one starts without pausing anyone and never becomes
  /// [currentVideoPlaying], which is what lets a screen full of muted loops
  /// animate together.
  ///
  /// The volume is deliberately untouched here. Forcing an unmute on this path
  /// made a player created with `initialVolume: 0` audible; keeping the volume
  /// is [GlobalVolumeSynchronizer]'s job.
  Future<void> requestPlay(OmniPlaybackController controller) async {
    await _lock.synchronized(() async {
      if (controller.isMuted) {
        await controller.play(useGlobalController: false);
        await _syncWakelock();
        return;
      }

      await _claimExclusivity(controller);
      await controller.play(useGlobalController: false);

      await _syncWakelock();
      notifyListeners();
    });
  }

  /// Hands exclusivity to [controller], pausing whoever held it.
  ///
  /// Caller must already hold [_lock].
  Future<void> _claimExclusivity(OmniPlaybackController controller) async {
    if (_currentVideoPlaying != null && _currentVideoPlaying != controller) {
      await _currentVideoPlaying!
          .pause(useGlobalController: false)
          .catchError((e) => debugPrint('Failed to pause previous player: $e'));
    }
    _currentVideoPlaying = controller;
  }

  /// Moves [controller] in or out of exclusivity after its volume changed.
  ///
  /// Audibility is evaluated when it matters, not fixed at construction: a
  /// player the user unmutes mid-playback joins exclusivity and pauses the
  /// current audible one, and muting the current player releases it without
  /// stopping it.
  Future<void> handleVolumeChanged(OmniPlaybackController controller) async {
    await _lock.synchronized(() async {
      if (controller.isMuted) {
        if (_currentVideoPlaying != controller) return;
        _currentVideoPlaying = null;
      } else {
        if (_currentVideoPlaying == controller) return;
        await _claimExclusivity(controller);
      }

      await _syncWakelock();
      notifyListeners();
    });
  }

  /// Memoised so [_syncWakelock] only touches the platform channel on a real
  /// transition — every registered controller notifies on each position
  /// update, and without this the wakelock listener would hammer the channel
  /// on every frame instead of once per play/pause/mute/fullscreen change.
  bool _wakelockHeld = false;

  /// Keeps the wakelock on while some player deserves to hold the screen awake.
  ///
  /// Audible players do, and so do fullscreen ones — muting a video you are
  /// watching full screen should not let the display go to sleep. A wall of
  /// decorative muted loops does not.
  ///
  /// Best-effort: a platform that refuses the wakelock must not take playback
  /// down with it.
  Future<void> _syncWakelock() async {
    final shouldHold = _allControllers.any(
      (c) => !c.isDisposed && c.isPlaying && (!c.isMuted || c.isFullScreen),
    );
    if (shouldHold == _wakelockHeld) return;
    _wakelockHeld = shouldHold;
    await (shouldHold ? WakelockPlus.enable() : WakelockPlus.disable())
        .catchError((e) => debugPrint('Failed to update wakelock: $e'));
  }

  /// Pauses the current audible video and releases the wakelock if nobody else
  /// needs it.
  Future<void> requestPause() async {
    await _lock.synchronized(() async {
      final player = _currentVideoPlaying;

      await player?.pause(useGlobalController: false);
      _currentVideoPlaying = null;
      await _syncWakelock();
      notifyListeners();
    });
  }
}
