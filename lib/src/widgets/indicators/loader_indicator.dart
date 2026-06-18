import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/widgets/opaque_control_surfaces.dart';

class LoaderIndicator extends StatelessWidget {
  const LoaderIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OpaqueControlSurfaces.of(context)
            ? theme.colors.controlButtonBackground
            : theme.colors.controlButtonBackground.withAlpha(100),
        borderRadius: BorderRadius.circular(200),
      ),
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.colors.controlButtonIcon ?? theme.colors.icon ?? Colors.white,
        ),
      ),
    );
  }
}
