import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/utils/accessibility/accessible.dart';
import 'package:omni_video_player/src/widgets/controls/overlay_button_wrapper.dart';

import 'video_control_icon_button.dart';

class PlaybackSpeedMenuButton extends StatelessWidget {
  final List<double> speedList;
  final double currentSpeed;
  final void Function(double selectedSpeed) onSpeedSelected;
  final VoidCallback onStartInteraction;
  final VoidCallback onEndInteraction;

  const PlaybackSpeedMenuButton({
    super.key,
    required this.speedList,
    required this.currentSpeed,
    required this.onSpeedSelected,
    required this.onStartInteraction,
    required this.onEndInteraction,
  });

  Widget _buildMenu(
    OmniVideoPlayerThemeData theme,
    VoidCallback dismissOverlay,
  ) {
    return Card(
      elevation: 8,
      color: theme.colors.menuBackground,
      child: SizedBox(
        width: 110,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          children: speedList.map((speed) {
            final isSelected = speed == currentSpeed;
            return Accessible.clickable(
              onTap: () {
                onSpeedSelected(speed);
                dismissOverlay();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (isSelected && speedList.length > 1)
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return OverlayButtonWrapper(
      childBuilder: (toggleOverlay, expanded) => VideoControlIconButton(
        semanticLabel: theme.accessibility.playbackSpeedButtonLabel,
        expanded: expanded,
        onPressed: toggleOverlay,
        icon: theme.icons.playbackSpeedButton,
      ),
      overlayBuilder: (dismissOverlay) => _buildMenu(theme, dismissOverlay),
      onStartInteraction: onStartInteraction,
      onEndInteraction: onEndInteraction,
    );
  }
}
