import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';

/// Manages global video-player behavior to ensure a single active playback,
/// consistent audio settings, and appropriate wakelock handling.
///
/// This class uses a [Lock] to serialize play/pause requests, preventing
/// race conditions when multiple controllers request playback simultaneously.
/// It delegates actual playback to each [CustomVideoPlayerController]'s
/// internal methods, ensuring the global manager can pause the previous
/// video before starting a new one. Wakelock is enabled during playback
/// to keep the screen awake and disabled when paused to conserve battery.
class GlobalPlaybackController extends Cubit<GlobalPlaybackControllerState> {
  /// Ensures exclusive access to play/pause operations, avoiding
  /// overlapping calls that could lead to inconsistent state or
  /// multiple videos playing at once.
  final Lock _lock = Lock();
  double _previousVolumeValue = 1.0;

  /// Initializes the manager with a default state (volume=1, no active player).
  ///
  /// Using Cubit allows emitting new immutable states and
  /// subscribing UI components to react to changes (e.g., showing
  /// a different UI when a video starts or stops).
  GlobalPlaybackController() : super(_initialState) {
    _initVolumeListener();
  }

  /// Initializes the system volume listener and syncs it with the global state.
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
  Future<void> close() {
    VolumeController.instance.removeListener();
    return super.close();
  }

  /// Updates the current volume setting in the shared state.
  ///
  /// Separating volume management here provides a single source
  /// of truth, enabling volume controls to affect all players
  /// uniformly and allowing UI widgets to rebuild when volume changes.
  void setCurrentVolume(double currentVolume) {
    emit(state.copyWith(currentVolume: currentVolume));
  }

  /// Requests playing [controller], pausing any existing video first.
  ///
  /// - Uses [_lock] to ensure that pause and play operations are atomic.
  /// - Pauses the currently playing controller via its internalPause(),
  ///   avoiding public pause() which might re-enter the lock and cause deadlocks.
  /// - Calls internalPlay() on the new controller to avoid circular
  ///   delegation back to this manager.
  /// - Enables wakelock to prevent screen timeout during video playback.
  /// - Emits an updated state with the new active [controller].
  Future<void> requestPlay(OmniPlaybackController controller) async {
    await _lock.synchronized(() async {
      // Se è già il video in riproduzione, non fare nulla
      if (state.currentVideoPlaying == controller) {
        return;
      }

      // Pause the previous video to enforce single playback.
      await state.currentVideoPlaying?.pause(useGlobalController: false);

      // Start the new video without re-entering this manager.
      await controller.play(useGlobalController: false);

      // Keep the device awake during playback for a seamless experience.
      await WakelockPlus.enable();

      if (!isClosed) {
        // Update state last to trigger UI updates after playback begins.
        emit(state.copyWith(currentVideoPlaying: controller));
      }
    });
  }

  /// Requests pausing of the currently active video.
  ///
  /// - Serialized via [_lock] to match the play logic and maintain order.
  /// - Disables wakelock to allow the screen to sleep and save power.
  /// - Pauses the active video internally, then clears the active player
  ///   in the emitted state.
  Future<void> requestPause() async {
    await _lock.synchronized(() async {
      final player = state.currentVideoPlaying;

      // Allow screen to sleep now that playback is paused.
      await WakelockPlus.disable();

      await player?.pause(useGlobalController: false);

      if (!isClosed) {
        emit(
          GlobalPlaybackControllerState(
            currentVolume: state.currentVolume,
            currentVideoPlaying: null,
          ),
        );
      }
    });
  }

  /// The initial state: full volume, no video playing.
  static const GlobalPlaybackControllerState _initialState =
      GlobalPlaybackControllerState(currentVolume: 1);
}

///Class for managing global video-players behaviours:
/// - current audioMode
/// ecc... (For example: unique video player playback)
@immutable
class GlobalPlaybackControllerState {
  const GlobalPlaybackControllerState({
    required this.currentVolume,
    this.currentVideoPlaying,
  });

  final double currentVolume;
  final OmniPlaybackController? currentVideoPlaying;

  bool get isMute => currentVolume == 0;

  GlobalPlaybackControllerState copyWith({
    double? currentVolume,
    OmniPlaybackController? currentVideoPlaying,
  }) =>
      GlobalPlaybackControllerState(
        currentVolume: currentVolume ?? this.currentVolume,
        currentVideoPlaying: currentVideoPlaying ?? this.currentVideoPlaying,
      );
}
