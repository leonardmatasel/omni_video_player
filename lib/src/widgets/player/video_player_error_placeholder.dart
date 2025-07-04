import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/src/utils/logger.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

/// A default error placeholder widget for the video player.
///
/// [VideoPlayerErrorPlaceholder] is shown when video playback fails due to an error.
/// It displays a themed icon, error message, and optionally provides a button
/// to open the video URL in an external video player app.
///
/// The appearance and text are styled based on the current [OmniVideoPlayerTheme].
class VideoPlayerErrorPlaceholder extends StatelessWidget {
  /// Creates the error placeholder widget.
  ///
  /// If [videoUrlToOpenExternally] is provided, a button is shown
  /// that allows the user to open the video in an external app.
  const VideoPlayerErrorPlaceholder({
    super.key,
    required this.playerGlobalKey,
    required this.videoUrlToOpenExternally,
    required this.showRefreshButton,
  });

  /// The video URL to open in an external player, if applicable.
  final String? videoUrlToOpenExternally;

  final bool? showRefreshButton;

  final GlobalKey<VideoPlayerInitializerState> playerGlobalKey;

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
            if (videoUrlToOpenExternally != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (defaultTargetPlatform == TargetPlatform.android) {
                      final AndroidIntent intent = AndroidIntent(
                        action: 'action_view',
                        data: videoUrlToOpenExternally!,
                      );
                      await intent.launch();
                    } else {
                      try {
                        await launchUrl(Uri.parse(videoUrlToOpenExternally!));
                      } catch (e, s) {
                        logger.w(
                          'Failed to launch external video URL',
                          error: e,
                          stackTrace: s,
                        );
                      }
                    }
                  },
                  child: Text(theme.labels.openExternalLabel),
                ),
              ),
            if (showRefreshButton != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton(
                  onPressed: () async {
                    playerGlobalKey.currentState?.refresh();
                  },
                  child: Text(theme.labels.refreshLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
