import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/widgets/controls/audio_toggle_button.dart';

class VolumeSliderControl extends StatefulWidget {
  final OmniPlaybackController controller;
  final void Function(bool isMuted)? onAudioToggled;

  final VoidCallback? onStartInteraction;
  final VoidCallback? onEndInteraction;

  const VolumeSliderControl({
    super.key,
    required this.controller,
    this.onAudioToggled,
    this.onStartInteraction,
    this.onEndInteraction,
  });

  @override
  State<VolumeSliderControl> createState() => _VolumeSliderControlState();
}

class _VolumeSliderControlState extends State<VolumeSliderControl> {
  bool _isSliderVisible = false;
  bool _isInteracting = false;
  Timer? _hideTimer;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _onEnter() {
    widget.onStartInteraction?.call();

    _hideTimer?.cancel();
    if (!_isSliderVisible) {
      _isSliderVisible = true;
      _showOverlay();
    }
  }

  void _onExit() {
    _hideTimer?.cancel();

    if (_isInteracting) return;

    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_isInteracting) {
        _isSliderVisible = false;
        _removeOverlay();
        widget.onEndInteraction?.call();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final theme = OmniVideoPlayerTheme.of(context)!;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 36,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -105),
            child: MouseRegion(
              onEnter: (_) => _onEnter(),
              onExit: (_) => _onExit(),
              child: Listener(
                onPointerDown: (_) {
                  _isInteracting = true;
                  _hideTimer?.cancel();
                  widget.onStartInteraction?.call();
                },
                onPointerUp: (_) {
                  _isInteracting = false;
                  _onExit();
                },
                onPointerCancel: (_) {
                  _isInteracting = false;
                  _onExit();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 100,
                    width: 36,
                    decoration:
                        theme.menus.menuDecoration ??
                        BoxDecoration(
                          color: theme.colors.volumeOverlayBackground,
                          borderRadius: BorderRadius.circular(
                            theme.shapes.menuBorderRadius,
                          ),
                        ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape:
                              theme.shapes.volumeSliderThumbShape ??
                              const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 0,
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: widget.controller,
                          builder: (context, child) {
                            final double displayVolume =
                                widget.controller.isMuted
                                ? 0.0
                                : widget.controller.volume;

                            final Color currentSliderColor =
                                displayVolume <= 0.0
                                ? theme.colors.volumeColorInactiveSlider
                                : theme.colors.volumeColorActiveSlider;

                            return Slider(
                              value: displayVolume,
                              min: 0.0,
                              max: 1.0,
                              activeColor: currentSliderColor,
                              thumbColor: currentSliderColor,
                              inactiveColor: theme.colors.inactive,
                              onChanged: (value) {
                                if (widget.controller.isMuted && value > 0) {
                                  widget.onAudioToggled?.call(false);
                                }
                                widget.controller.volume = value;
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return AudioToggleButton(
        controller: widget.controller,
        onAudioToggled: widget.onAudioToggled,
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: AudioToggleButton(
          controller: widget.controller,
          onAudioToggled: widget.onAudioToggled,
        ),
      ),
    );
  }
}
