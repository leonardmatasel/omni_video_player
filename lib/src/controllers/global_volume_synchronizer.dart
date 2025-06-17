import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';

/// A widget that synchronizes the video player's volume
/// with the global volume state managed by [GlobalPlaybackController].
///
/// ### Purpose:
/// Ensures the volume of a specific [OmniPlaybackController] stays in sync
/// with a globally shared volume level. This is useful when you want all
/// players in the app to have a consistent audio setting (e.g., mute/unmute sync).
///
/// ### Requirements:
/// - Must be used inside a `BlocProvider` that provides a [GlobalPlaybackController].
///
/// ### Example:
/// ```dart
/// BlocProvider(
///   create: (_) => GlobalPlaybackController(),
///   child: GlobalVolumeSynchronizer(
///     controller: mediaController,
///     child: OmniVideoPlayer(...),
///   ),
/// )
/// ```
class GlobalVolumeSynchronizer extends StatefulWidget {
  /// The child widget to display (typically your video player).
  final Widget child;

  /// The [OmniPlaybackController] whose volume will be synced.
  final OmniPlaybackController controller;

  const GlobalVolumeSynchronizer({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<GlobalVolumeSynchronizer> createState() =>
      _GlobalVolumeSynchronizerState();
}

class _GlobalVolumeSynchronizerState extends State<GlobalVolumeSynchronizer> {
  GlobalPlaybackController? _globalPlaybackController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initGlobalVolumeSync();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _initGlobalVolumeSync() {
    try {
      _globalPlaybackController = context.read<GlobalPlaybackController>();
      _subscription = _globalPlaybackController!.stream.listen(
        _onGlobalVolumeChanged,
      );
      _onGlobalVolumeChanged(_globalPlaybackController!.state);
    } catch (e) {
      debugPrint(
        '[GlobalVolumeSynchronizer] No GlobalPlaybackController found. '
        'Wrap your widget with BlocProvider<GlobalPlaybackController> to enable volume sync.',
      );
    }
  }

  void _onGlobalVolumeChanged(GlobalPlaybackControllerState globalState) {
    widget.controller.volume = globalState.currentVolume;
  }
}
