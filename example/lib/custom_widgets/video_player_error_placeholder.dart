import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

/// A fallback widget displayed when video playback fails.
///
/// The [VideoPlayerErrorPlaceholder] provides a user-friendly error UI that includes:
/// - An error icon and message styled via [OmniVideoPlayerTheme].
/// - An optional button to open the video URL in an external player app.
/// - An optional refresh button to retry loading the video using [playerGlobalKey].
///
/// This widget is designed to offer graceful error recovery and guidance to the user.
///
/// {@tool snippet}
/// Example usage:
/// ```dart
/// VideoPlayerErrorPlaceholder(
///   playerGlobalKey: playerKey,
///   videoUrlToOpenExternally: videoUrl,
///   showRefreshButton: true,
/// )
/// ```
/// {@end-tool}
class VideoPlayerErrorPlaceholder extends StatelessWidget {
  /// Creates a [VideoPlayerErrorPlaceholder].
  ///
  /// If [videoUrlToOpenExternally] is non-null, an "Open in external player" button is shown.
  /// If [showRefreshButton] is `true`, a "Refresh" button is also displayed.
  const VideoPlayerErrorPlaceholder({
    super.key,
    required this.playerGlobalKey,
    required this.videoUrlToOpenExternally,
    required this.showRefreshButton,
  });

  /// Optional URL to open the video in an external app.
  ///
  /// If provided, the widget shows a button that attempts to launch the video externally.
  final String? videoUrlToOpenExternally;

  /// Whether to display a refresh button to retry video playback.
  final bool? showRefreshButton;

  /// A reference to the video player's state, used to trigger refresh actions.
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
                      final intent = AndroidIntent(
                        action: 'action_view',
                        data: videoUrlToOpenExternally!,
                      );
                      await intent.launch();
                    } else {
                      await launchUrl(Uri.parse(videoUrlToOpenExternally!));
                    }
                  },
                  child: Text(theme.labels.openExternalLabel),
                ),
              ),
            if (showRefreshButton == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton(
                  onPressed: () {
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
