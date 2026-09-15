import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// Il player dentro una OverlayEntry del Navigator: vive accanto alla route,
/// non dentro, quindi non ha nessuna ModalRoute sopra di se'.
class OverlayVideo extends StatelessWidget {
  const OverlayVideo({super.key});

  void _openOverlay(BuildContext context) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OverlayPlayer(onClose: () => entry.remove()),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: Center(
        child: FilledButton.icon(
          onPressed: () => _openOverlay(context),
          icon: const Icon(Icons.picture_in_picture_alt),
          label: const Text('Apri il video in overlay'),
        ),
      ),
    );
  }
}

class _OverlayPlayer extends StatelessWidget {
  const _OverlayPlayer({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              // Senza un box vincolato il player prende tutta l'altezza e la
              // barra dei controlli finisce a fondo schermo, lontana dal video.
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: OmniVideoPlayer(
                  callbacks: VideoPlayerCallbacks(),
                  configuration: VideoPlayerConfiguration(
                    videoSourceConfiguration: VideoSourceConfiguration.network(
                      videoUrl: Uri.parse(
                        'https://www.w3schools.com/tags/mov_bbb.mp4',
                      ),
                    ).copyWith(autoPlay: true),
                    playerUIVisibilityOptions: PlayerUIVisibilityOptions(
                      showFullScreenButton: true,
                      showPlaybackSpeedButton: true,
                      enableZoom: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
