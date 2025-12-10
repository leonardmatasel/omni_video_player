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

  OmniPlaybackController? get currentVideoPlaying => _currentVideoPlaying;
  double get currentVolume => _currentVolume;
  bool get isMute => _currentVolume == 0;

  GlobalPlaybackController._internal() {
    _initVolumeListener();
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
      if (_currentVideoPlaying == controller) return;

      try {
        await _currentVideoPlaying?.pause(useGlobalController: false);
      } catch (_) {}

      if (_currentVolume > 0) {
        controller.unMute();
      } else if (_currentVolume == 0) {
        controller.mute();
      }
      await controller.play(useGlobalController: false);

      await WakelockPlus.enable();

      _currentVideoPlaying = controller;
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
