import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that mimics the status bar height and applies a customizable
/// system UI overlay style, intended for use in layouts without an AppBar.
///
/// This widget is especially useful in fullscreen mode to properly account
/// for the status bar height and apply appropriate color and icon styling,
/// preventing layout issues when no native AppBar is present.
///
/// It implements [PreferredSizeWidget] so it can be used in places expecting
/// an AppBar or similar widget.
class TransparentStatusBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The [MediaQueryData] from which the top padding (status bar height) is derived.
  final MediaQueryData mediaQueryData;

  /// Optional style for the system overlays (status bar icons and background color).
  final SystemUiOverlayStyle? systemUiOverlayStyle;

  /// Creates a [TransparentStatusBar] that occupies the status bar height
  /// and applies the given [systemUiOverlayStyle].
  const TransparentStatusBar({
    super.key,
    required this.mediaQueryData,
    this.systemUiOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: preferredSize.height,
      systemOverlayStyle: systemUiOverlayStyle,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(mediaQueryData.padding.top);
}
