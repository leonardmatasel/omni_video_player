import 'package:flutter/material.dart';

/// Widget wrapper generico per overlay legati a un pulsante
class OverlayButtonWrapper extends StatefulWidget {
  const OverlayButtonWrapper({
    super.key,
    required this.childBuilder,
    required this.overlayBuilder,
    this.targetAnchor = Alignment.topCenter,
    this.followerAnchor = Alignment.bottomCenter,
    this.onOverlayToggled,
  });

  /// Builder del pulsante: riceve toggleOverlay
  final Widget Function(VoidCallback toggleOverlay, bool expanded) childBuilder;

  /// Builder dell'overlay, riceve una funzione dismiss per chiuderlo
  final Widget Function(VoidCallback dismissOverlay) overlayBuilder;

  final Alignment targetAnchor;

  final Alignment followerAnchor;

  /// Optional callback invoked when the overlay opens (true) or closes (false).
  final void Function(bool isOpen)? onOverlayToggled;

  @override
  State<OverlayButtonWrapper> createState() => _OverlayButtonWrapperState();
}

class _OverlayButtonWrapperState extends State<OverlayButtonWrapper> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  void _dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
    widget.onOverlayToggled?.call(false);
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _dismissOverlay();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Cattura i tocchi fuori dall'overlay
            Positioned.fill(
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissOverlay,
                ),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: widget.targetAnchor,
              followerAnchor: widget.followerAnchor,
              child: Material(
                color: Colors.transparent,
                child: widget.overlayBuilder(_dismissOverlay),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() {});
    widget.onOverlayToggled?.call(true);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.childBuilder(_toggleOverlay, _overlayEntry != null),
    );
  }
}
