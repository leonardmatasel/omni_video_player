import 'package:flutter/material.dart';

/// Represents a custom overlay layer that can be inserted
/// into the video player controls stack at a specific level.
///
/// The [widget] field holds the widget to display as the overlay,
/// while [level] determines the rendering depth/order in the stack.
/// Layers with lower levels are drawn below layers with higher levels.
///
/// The default [level] value is 1, but it can be customized
/// to precisely control where the widget is inserted in the stack.
///
/// ## Example usage of levels:
/// - 0: Main video (widget.child)
/// - 1: CustomOverlayLayer (default) / Transparent layer for tap detection (e.g., InAppWebView)
/// - 2: Double tap area for rewind/forward gestures (GestureDetector)
/// - 3: Skip indicator with fade out animation
/// - 4: Bottom control bar with gradient and playback controls
/// - 5: Loader indicator (shown during seeking)
/// - 6: Central play/pause button with auto-hide behavior
///
/// This order allows you to position your custom overlay flexibly,
/// for example above the video but below the control bar.
///
/// ```dart
/// final overlay = CustomOverlayLayer(
///   widget: MyCustomOverlayWidget(),
///   level: 1,
///   ignoreOverlayControlsVisibility: true,
/// );
/// ```
///
/// In the example above, the custom overlay will be shown above the video
/// and rendered regardless of the control visibility state.
class CustomOverlayLayer {
  /// The widget to display as the overlay.
  final Widget widget;

  /// The depth level in the widget stack.
  ///
  /// Widgets with lower levels are drawn below those with higher levels.
  /// The default value is 1, which places it above the video but below
  /// most control elements.
  final int level;

  /// Whether to ignore the visibility of overlay controls.
  ///
  /// If set to true, this overlay will be shown even when
  /// overlay controls are hidden (e.g., auto-hide behavior).
  final bool ignoreOverlayControlsVisibility;

  CustomOverlayLayer({
    required this.widget,
    this.level = 1,
    this.ignoreOverlayControlsVisibility = false,
  });
}
