import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/custom_overlay_layer.dart';

/// Defines custom UI components for the video player, allowing you to override
/// default widgets like loading indicators, error placeholders, and control bar elements.
///
/// Use this class to personalize the look and behavior of the player without
/// altering the core logic.
@immutable
class CustomPlayerWidgets {
  /// Widget displayed while the video player is initializing or buffering.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget loadingWidget;

  /// Widget displayed when an error occurs during playback initialization or runtime.
  ///
  /// Can be used to show retry buttons or custom error messages.
  final Widget? errorPlaceholder;

  /// Widget used to replace the entire bottom control bar.
  ///
  /// Use this to provide a fully custom layout and interactions.
  final Widget? bottomControlsBar;

  /// Widgets displayed on the **left (leading)** side of the bottom control bar.
  ///
  /// Common use cases include play/pause or mute/unmute buttons.
  final List<Widget> leadingBottomButtons;

  /// Widgets displayed on the **right (trailing)** side of the bottom control bar.
  ///
  /// Typically used for fullscreen toggle, settings, etc.
  final List<Widget> trailingBottomButtons;

  /// Widget used to replace the default seek bar / progress bar.
  ///
  /// Allows full customization of the timeline UI.
  final Widget? customSeekBar;

  /// Widget used to replace the default current time / total duration display.
  final Widget? customDurationDisplay;

  /// Widget used to replace the default remaining time indicator.
  final Widget? customRemainingTimeDisplay;

  /// Widgets shown above the video content.
  ///
  /// The order of the list is important: layers are added in sequence and can cause shifting.
  final List<CustomOverlayLayer> customOverlayLayers;

  /// Optional thumbnail image displayed before playback starts.
  ///
  /// This is commonly used to preview the video content. The thumbnail is removed
  /// once the video begins playback.
  ///
  /// The background behind this image can be customized via `PlayerThemeData.backgroundColor`.
  final ImageProvider<Object>? thumbnail;

  /// Defines how the [thumbnail] is scaled inside its container.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit thumbnailFit;

  /// Optional wrapper applied **only in fullscreen mode**.
  ///
  /// Use this to wrap the entire player in a different layout or theme
  /// when entering fullscreen. For example, you could add padding,
  /// a background gradient, or a safe area.
  ///
  /// Example:
  /// ```dart
  /// fullscreenWrapper: (context, child) => Scaffold(
  ///   backgroundColor: Colors.black,
  ///   body: Center(child: child),
  /// ),
  /// ```
  final Widget Function(BuildContext context, Widget child)? fullscreenWrapper;

  /// Creates a new instance of [CustomPlayerWidgets] with optional overrides
  /// for all supported customizations.
  const CustomPlayerWidgets({
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorPlaceholder,
    this.bottomControlsBar,
    this.leadingBottomButtons = const [],
    this.trailingBottomButtons = const [],
    this.customSeekBar,
    this.customDurationDisplay,
    this.customRemainingTimeDisplay,
    this.thumbnail,
    this.thumbnailFit = BoxFit.cover,
    this.customOverlayLayers = const [],
    this.fullscreenWrapper,
  });

  /// Returns a new [CustomPlayerWidgets] instance with the specified fields overridden.
  ///
  /// Use this method to selectively override parts of an existing configuration.
  ///
  /// Example:
  /// ```dart
  /// final updatedWidgets = oldWidgets.copyWith(
  ///   loadingWidget: CircularProgressIndicator(color: Colors.red),
  ///   thumbnail: AssetImage("assets/preview.png"),
  /// );
  /// ```
  CustomPlayerWidgets copyWith({
    Widget? loadingWidget,
    Widget? errorPlaceholder,
    Widget? bottomControlsBar,
    List<Widget>? leadingBottomButtons,
    List<Widget>? trailingBottomButtons,
    Widget? customSeekBar,
    Widget? customDurationDisplay,
    Widget? customRemainingTimeDisplay,
    ImageProvider<Object>? thumbnail,
    BoxFit? thumbnailFit,
    List<CustomOverlayLayer>? customOverlayLayers,
    Widget Function(BuildContext context, Widget child)? fullscreenWrapper,
  }) {
    return CustomPlayerWidgets(
      loadingWidget: loadingWidget ?? this.loadingWidget,
      errorPlaceholder: errorPlaceholder ?? this.errorPlaceholder,
      bottomControlsBar: bottomControlsBar ?? this.bottomControlsBar,
      leadingBottomButtons: leadingBottomButtons ?? this.leadingBottomButtons,
      trailingBottomButtons:
          trailingBottomButtons ?? this.trailingBottomButtons,
      customSeekBar: customSeekBar ?? this.customSeekBar,
      customDurationDisplay:
          customDurationDisplay ?? this.customDurationDisplay,
      customRemainingTimeDisplay:
          customRemainingTimeDisplay ?? this.customRemainingTimeDisplay,
      thumbnail: thumbnail ?? this.thumbnail,
      thumbnailFit: thumbnailFit ?? this.thumbnailFit,
      customOverlayLayers: customOverlayLayers ?? this.customOverlayLayers,
      fullscreenWrapper: fullscreenWrapper ?? this.fullscreenWrapper,
    );
  }
}
