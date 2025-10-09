import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

import 'video_control_icon_button.dart';

class PlaybackSpeedMenuButton extends StatefulWidget {
  final List<double> speedList;
  final double currentSpeed;
  final void Function(double selectedSpeed) onSpeedSelected;

  const PlaybackSpeedMenuButton({
    super.key,
    required this.speedList,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  State<PlaybackSpeedMenuButton> createState() =>
      _PlaybackSpeedMenuButtonState();
}

class _PlaybackSpeedMenuButtonState extends State<PlaybackSpeedMenuButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late double selectedSpeed;

  @override
  void initState() {
    super.initState();
    selectedSpeed = widget.currentSpeed;
  }

  @override
  void didUpdateWidget(covariant PlaybackSpeedMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSpeed != widget.currentSpeed) {
      selectedSpeed = widget.currentSpeed;
    }
  }

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _showMenu();
    } else {
      _removeMenu();
    }
  }

  void _showMenu() {
    final RenderBox buttonRenderBox = context.findRenderObject()! as RenderBox;
    final position = buttonRenderBox.localToGlobal(Offset.zero);
    final theme = OmniVideoPlayerTheme.of(context)!;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeMenu,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy - _menuHeight(),
              width: 100,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(-50, -_menuHeight()),
                child: _buildMenu(theme),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  double _menuHeight() {
    const double itemHeight = 48;
    return widget.speedList.length * itemHeight + 16;
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildMenu(OmniVideoPlayerThemeData theme) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: theme.colors.menuBackground,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        children: widget.speedList.map((speed) {
          final isSelected = speed == selectedSpeed;
          return InkWell(
            onTap: () {
              setState(() {
                selectedSpeed = speed;
              });
              widget.onSpeedSelected(speed);
              _removeMenu();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${speed}x",
                    style: TextStyle(
                      color: isSelected
                          ? theme.colors.menuTextSelected
                          : theme.colors.menuText,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      theme
                          .icons
                          .qualitySelectedCheck, // puoi usare una icona simile
                      color: theme.colors.menuIconSelected,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return CompositedTransformTarget(
      link: _layerLink,
      child: VideoControlIconButton(
        onPressed: _toggleMenu,
        icon: theme.icons.playbackSpeedButton,
      ),
    );
  }
}
