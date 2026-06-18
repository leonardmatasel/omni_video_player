import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  group('YoutubeWebViewConfiguration.onExternalLink', () {
    test('defaults to null and copyWith sets it', () {
      const a = YoutubeWebViewConfiguration();
      expect(a.onExternalLink, isNull);
      void cb(Uri _) {}
      final b = a.copyWith(onExternalLink: cb);
      expect(b.onExternalLink, same(cb));
    });

    test('callback is excluded from == / hashCode', () {
      final a = YoutubeWebViewConfiguration(onExternalLink: (Uri _) {});
      const b = YoutubeWebViewConfiguration();
      expect(a, b); // differ only by callback -> still equal
      expect(a.hashCode, b.hashCode);
    });
  });

  group('VideoSourceConfiguration.youtubeWebView', () {
    test('defaults: native controls on, no force, fallback on', () {
      final c = VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://youtu.be/abc'),
      );
      expect(c.youtubeWebView.useNativeControls, isTrue);
      expect(c.youtubeWebView.forceWebViewOnly, isFalse);
      expect(c.youtubeWebView.enableFallback, isTrue);
    });

    test('factory accepts a grouped webView config', () {
      final c = VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://youtu.be/abc'),
        webView: const YoutubeWebViewConfiguration(
          forceWebViewOnly: true,
          useNativeControls: false,
        ),
      );
      expect(c.youtubeWebView.forceWebViewOnly, isTrue);
      expect(c.youtubeWebView.useNativeControls, isFalse);
      expect(c.youtubeWebView.enableFallback, isTrue); // default kept
    });

    test('copyWith replaces the group; equality/hashCode reflect it', () {
      final a = VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://youtu.be/abc'),
      );
      final b = a.copyWith(
        youtubeWebView:
            const YoutubeWebViewConfiguration(useNativeControls: false),
      );
      expect(b.youtubeWebView.useNativeControls, isFalse);
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('YoutubeWebViewConfiguration value equality', () {
      expect(
        const YoutubeWebViewConfiguration(),
        const YoutubeWebViewConfiguration(useNativeControls: true),
      );
      expect(
        const YoutubeWebViewConfiguration(forceWebViewOnly: true),
        isNot(const YoutubeWebViewConfiguration()),
      );
    });
  });
}
