import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omni_video_player/src/controllers/video_playback_controller.dart';

import 'progress_bar.dart';
import '../../../omni_video_player/controllers/omni_playback_controller.dart';

class ProgressBarWithPreview extends StatefulWidget {
  final OmniPlaybackController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final bool allowSeeking;
  final bool showScrubbingThumbnailPreview;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeStart;
  final ValueChanged<Duration>? onChangeEnd;

  const ProgressBarWithPreview({
    super.key,
    required this.controller,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.allowSeeking,
    required this.showScrubbingThumbnailPreview,
  });

  @override
  State<ProgressBarWithPreview> createState() => _ProgressBarWithPreviewState();
}

class _ProgressBarWithPreviewState extends State<ProgressBarWithPreview> {
  double? _dragValue;
  bool _showPreview = false;
  Duration previousDuration = Duration.zero;
  VideoPlaybackController? _previewController;

  @override
  void initState() {
    super.initState();
    if (widget.controller.videoUrl != null) {
      _previewController = VideoPlaybackController.uri(
        widget.controller.videoUrl!.toString(),
      );
    } else if (widget.controller.videoDataSource != null) {
      _previewController = VideoPlaybackController.asset(
        widget.controller.videoDataSource!,
      );
    } else if (widget.controller.file != null) {
      _previewController = VideoPlaybackController.file(
        widget.controller.file!,
      );
    }
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  void _onChangeStart(double value) {
    setState(() => _showPreview = true);
    widget.onChangeStart?.call(Duration(milliseconds: value.round()));
  }

  void _onChanged(double value) {
    setState(() {
      _dragValue = value;
    });
    if (_previewController != null &&
        (value - previousDuration.inMilliseconds).abs() > 5000) {
      _previewController?.player.seek(Duration(milliseconds: value.round()));
      setState(() {});
    }

    widget.onChanged?.call(Duration(milliseconds: value.round()));
  }

  void _onChangeEnd(double value) {
    widget.controller.seekTo(Duration(milliseconds: value.round()));
    setState(() {
      _dragValue = null;
      _showPreview = false;
    });
    widget.onChangeEnd?.call(Duration(milliseconds: value.round()));
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.currentPosition.inMilliseconds
        .toDouble();
    final duration = widget.controller.duration.inMilliseconds.toDouble();
    final displayValue = _dragValue ?? position;

    return LayoutBuilder(
      builder: (context, constraints) {
        final percent = (displayValue / duration).clamp(0.0, 1.0);
        final thumbX = constraints.maxWidth * percent;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // --- Il tuo ProgressBar originale ---
            ProgressBar(
              value: displayValue,
              max: duration,
              onChangeStart: _onChangeStart,
              onChanged: _onChanged,
              onChangeEnd: _onChangeEnd,
              allowSeeking: widget.allowSeeking,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
              thumbColor: widget.thumbColor,
            ),

            // --- Overlay preview video ---
            if (widget.showScrubbingThumbnailPreview &&
                _previewController != null &&
                _showPreview &&
                _previewController!.isReady)
              Positioned(
                left: (thumbX - 50).clamp(0, constraints.maxWidth - 100),
                bottom: 40,
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white24, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 160,
                        height: 122,
                        child: Video(
                          width: 160,
                          height: 122,
                          controller: _previewController!.videoController,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
