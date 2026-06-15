import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A premium error placeholder widget for the video player.
///
/// [OmniVideoPlayerErrorView] is shown when video playback fails due to an error.
/// It displays a themed icon, error message, and a retry button.
///
/// The appearance and text are styled based on the current [OmniVideoPlayerTheme].
class OmniVideoPlayerErrorView extends StatelessWidget {
  /// Callback triggered when the user taps the retry button.
  final VoidCallback? onRetry;

  const OmniVideoPlayerErrorView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Container(
      color: theme.colors.backgroundError.withValues(alpha: 0.85),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular error icon container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (theme.colors.textError).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (theme.colors.textError).withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      theme.icons.error,
                      color: theme.colors.textError,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Playback Error',
                    style: TextStyle(
                      color: theme.colors.textError,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.labels.errorMessage,
                    style: TextStyle(
                      color: theme.colors.textError.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colors.active,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: theme.colors.active.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: onRetry,
                      icon: Icon(theme.icons.replay, size: 18),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
