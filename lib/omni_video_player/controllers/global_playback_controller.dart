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
  bool _wasLastVideoFullscreen = false;
  bool _isFullscreenRouteOpen = false;

  /// A list of all active controllers to manage resources globally.
  final List<OmniPlaybackController> _allControllers = [];

  OmniPlaybackController? get currentVideoPlaying => _currentVideoPlaying;
  double get currentVolume => _currentVolume;
  bool get isMute => _currentVolume == 0;
  bool get wasLastVideoFullscreen => _wasLastVideoFullscreen;
  bool get isFullscreenRouteOpen => _isFullscreenRouteOpen;

  set wasLastVideoFullscreen(bool value) {
    _wasLastVideoFullscreen = value;
    notifyListeners();
  }

  set isFullscreenRouteOpen(bool value) {
    _isFullscreenRouteOpen = value;
    notifyListeners();
  }

  GlobalPlaybackController._internal() {
    _initVolumeListener();
  }

  /// Registers a controller to be tracked globally.
  void registerController(OmniPlaybackController controller) {
    if (!_allControllers.contains(controller)) {
      _allControllers.add(controller);
    }
    if (_isFullscreenRouteOpen) {
      _currentVideoPlaying = controller;
      notifyListeners();
    }
  }

  /// Unregisters a controller from global tracking.
  void unregisterController(OmniPlaybackController controller) {
    _allControllers.remove(controller);
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
      await WakelockPlus.disable();
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

  void setCurrentVolume(double volume) {
    _currentVolume = volume;
    notifyListeners();
  }

  /// Plays a video controller, pausing any previous one first.
  Future<void> requestPlay(OmniPlaybackController controller) async {
    await _lock.synchronized(() async {
      if (_currentVideoPlaying != null && _currentVideoPlaying != controller) {
        await _currentVideoPlaying!
            .pause(useGlobalController: false)
            .catchError(
              (e) => debugPrint('Failed to pause previous player: $e'),
            );
      }

      _currentVideoPlaying = controller;

      if (_currentVolume > 0) {
        controller.unMute();
      } else if (_currentVolume == 0) {
        controller.mute();
      }
      await controller.play(useGlobalController: false);

      await WakelockPlus.enable();
      notifyListeners();
    });
  }

  /// Pauses the current video and disables wakelock.
  Future<void> requestPause() async {
    await _lock.synchronized(() async {
      final player = _currentVideoPlaying;

      await WakelockPlus.disable();
      await player?.pause(useGlobalController: false);

      _currentVideoPlaying = null;
      notifyListeners();
    });
  }
}
