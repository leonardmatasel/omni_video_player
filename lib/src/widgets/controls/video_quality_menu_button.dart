import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

import 'video_control_icon_button.dart';

class VideoQualityMenuButton extends StatefulWidget {
  final List<OmniVideoQuality>? qualityList;
  final OmniVideoQuality? currentQuality;
  final void Function(OmniVideoQuality selectedQuality) onQualitySelected;

  const VideoQualityMenuButton({
    super.key,
    required this.qualityList,
    required this.currentQuality,
    required this.onQualitySelected,
  });

  @override
  State<VideoQualityMenuButton> createState() => _VideoQualityMenuButtonState();
}

class _VideoQualityMenuButtonState extends State<VideoQualityMenuButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late OmniVideoQuality? selectedQuality;

  @override
  void initState() {
    super.initState();
    selectedQuality = widget.currentQuality;
  }

  @override
  void didUpdateWidget(covariant VideoQualityMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuality != widget.currentQuality) {
      selectedQuality = widget.currentQuality;
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
    final size = buttonRenderBox.size;

    final menuHeight = _menuHeight();

    final theme = OmniVideoPlayerTheme.of(context)!;

    // Decidiamo se mostrare sopra o sotto
    final bool showAbove = position.dy >= menuHeight;

    final Offset offset = showAbove
        ? Offset(-60, -menuHeight) // sopra
        : Offset(-60, size.height); // sotto

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Trasparente per chiudere quando si tocca fuori
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeMenu,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            Positioned(
              left: position.dx,
              top: showAbove
                  ? position.dy - menuHeight
                  : position.dy + size.height,
              width: 120,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: offset,
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
    return (widget.qualityList?.length ?? 1) * itemHeight + 16;
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
        children: widget.qualityList == null
            ? [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        theme.labels.autoQualityLabel,
                        style: TextStyle(
                          color: theme.colors.menuTextSelected,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        theme.icons.qualitySelectedCheck,
                        color: theme.colors.menuIconSelected,
                        size: 18,
                      ),
                    ],
                  ),
                )
              ]
            : widget.qualityList!.map((quality) {
                final isSelected = quality == selectedQuality;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedQuality = quality;
                    });
                    widget.onQualitySelected(quality);
                    _removeMenu();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quality.qualityString,
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
                            theme.icons.qualitySelectedCheck,
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
        icon: theme.icons.qualityChangeButton,
      ),
    );
  }
}
