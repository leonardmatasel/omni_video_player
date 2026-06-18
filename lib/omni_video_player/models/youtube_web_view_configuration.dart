import 'package:flutter/foundation.dart';

/// Groups the YouTube **WebView** player flags.
@immutable
class YoutubeWebViewConfiguration {
  /// Force the WebView (iframe) player even when native extraction would work.
  final bool forceWebViewOnly;

  /// Fall back to the WebView player if native stream extraction fails.
  final bool enableFallback;

  /// Use YouTube's native center play/pause + double-tap (interactive iframe).
  /// When `false`, use the fully-custom Omni controls over a non-interactive
  /// iframe.
  final bool useNativeControls;

  /// Called when the user taps a link in the YouTube player that would navigate
  /// away (e.g. "Watch on YouTube", the title, channel, related videos, share).
  /// The navigation is always blocked; use this to react (e.g. open the URL with
  /// url_launcher). When null, the link is simply blocked.
  final void Function(Uri url)? onExternalLink;

  const YoutubeWebViewConfiguration({
    this.forceWebViewOnly = false,
    this.enableFallback = true,
    this.useNativeControls = true,
    this.onExternalLink,
  });

  YoutubeWebViewConfiguration copyWith({
    bool? forceWebViewOnly,
    bool? enableFallback,
    bool? useNativeControls,
    void Function(Uri url)? onExternalLink,
  }) {
    return YoutubeWebViewConfiguration(
      forceWebViewOnly: forceWebViewOnly ?? this.forceWebViewOnly,
      enableFallback: enableFallback ?? this.enableFallback,
      useNativeControls: useNativeControls ?? this.useNativeControls,
      onExternalLink: onExternalLink ?? this.onExternalLink,
    );
  }

  // onExternalLink is intentionally excluded from == and hashCode:
  // closures are not value-comparable and must not break value equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoutubeWebViewConfiguration &&
          other.forceWebViewOnly == forceWebViewOnly &&
          other.enableFallback == enableFallback &&
          other.useNativeControls == useNativeControls;

  @override
  int get hashCode =>
      Object.hash(forceWebViewOnly, enableFallback, useNativeControls);
}
