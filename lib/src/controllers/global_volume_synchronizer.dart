import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';

/// A widget that synchronizes a video player's volume
/// with the global volume state managed by [GlobalPlaybackController].
///
/// ### Purpose:
/// Keeps the volume of a specific [OmniPlaybackController]
/// in sync with a globally shared volume level (mute/unmute sync).
///
/// ### Notes:
/// - Works automatically with the global singleton instance of [GlobalPlaybackController].
/// - No Provider or external setup is required.
class GlobalVolumeSynchronizer extends StatefulWidget {
  final Widget child;
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
  late final GlobalPlaybackController _globalPlaybackController;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _globalPlaybackController = GlobalPlaybackController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initGlobalVolumeSync(),
    );
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _initGlobalVolumeSync() {
    _listener = () {
      widget.controller.volume = _globalPlaybackController.currentVolume;
    };

    // Initial sync
    widget.controller.volume = _globalPlaybackController.currentVolume;

    // Listen for future updates
    _globalPlaybackController.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      _globalPlaybackController.removeListener(_listener!);
    }
  }
}
