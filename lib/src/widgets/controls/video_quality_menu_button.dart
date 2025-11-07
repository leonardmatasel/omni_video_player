import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/utils/accessibility/accessible.dart';
import 'package:omni_video_player/src/widgets/controls/overlay_button_wrapper.dart';

import 'video_control_icon_button.dart';

class VideoQualityMenuButton extends StatelessWidget {
  final List<OmniVideoQuality>? qualityList;
  final OmniVideoQuality? currentQuality;
  final void Function(OmniVideoQuality selectedQuality) onQualitySelected;
  final VoidCallback onStartInteraction;
  final VoidCallback onEndInteraction;

  const VideoQualityMenuButton({
    super.key,
    required this.qualityList,
    required this.currentQuality,
    required this.onQualitySelected,
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
        width: 130,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          children: qualityList == null
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentQuality != null
                              ? "${theme.labels.autoQualityLabel} (${currentQuality!.qualityString})"
                              : theme.labels.autoQualityLabel,
                          style: TextStyle(
                            color: theme.colors.menuTextSelected,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : qualityList!.map((quality) {
                  final isSelected = quality == currentQuality;
                  return Accessible.clickable(
                    onTap: () {
                      onQualitySelected(quality);
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
                          if (isSelected && qualityList!.length > 1)
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
        semanticLabel: theme.accessibility.qualityButtonLabel,
        expanded: expanded,
        onPressed: toggleOverlay,
        icon: theme.icons.qualityChangeButton,
      ),
      overlayBuilder: (dismissOverlay) => _buildMenu(theme, dismissOverlay),
      onStartInteraction: onStartInteraction,
      onEndInteraction: onEndInteraction,
    );
  }
}
