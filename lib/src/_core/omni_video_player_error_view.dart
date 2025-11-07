import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A default error placeholder widget for the video player.
///
/// [OmniVideoPlayerErrorView] is shown when video playback fails due to an error.
/// It displays a themed icon, error message,
///
/// The appearance and text are styled based on the current [OmniVideoPlayerTheme].
class OmniVideoPlayerErrorView extends StatelessWidget {
  /// Creates the error placeholder widget.
  ///
  /// If [videoUrlToOpenExternally] is provided, a button is shown
  /// that allows the user to open the video in an external app.
  const OmniVideoPlayerErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Container(
      color: theme.colors.backgroundError,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(theme.icons.error, color: theme.colors.textError, size: 42),
            const SizedBox(height: 16),
            Text(
              theme.labels.errorMessage,
              style: TextStyle(color: theme.colors.textError),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
