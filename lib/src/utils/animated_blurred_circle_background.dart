import 'package:flutter/material.dart';

/// Animated widget that displays a smoothly moving blurred circle background.
class AnimatedBlurredCircleBackground extends StatefulWidget {
  final Color color;
  final int alpha;
  final Duration animationDuration;

  const AnimatedBlurredCircleBackground({
    super.key,
    this.color = Colors.red,
    this.alpha = 100,
    this.animationDuration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedBlurredCircleBackground> createState() =>
      _AnimatedBlurredCircleBackgroundState();
}

class _AnimatedBlurredCircleBackgroundState
    extends State<AnimatedBlurredCircleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _xOffset;
  late final Animation<double> _yOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);

    _xOffset = _createOffsetTween();
    _yOffset = _createOffsetTween();
  }

  Animation<double> _createOffsetTween() {
    return Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final center = Offset(
              constraints.maxWidth * _xOffset.value,
              constraints.maxHeight * _yOffset.value,
            );

            return CustomPaint(
              size: constraints.biggest,
              painter: BlurredCirclePainter(
                color: widget.color,
                alpha: widget.alpha,
                center: center,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Draws a blurred circle background for aesthetic overlay effects.
class BlurredCirclePainter extends CustomPainter {
  final Color color;
  final int alpha;
  final Offset center;

  BlurredCirclePainter({
    required this.color,
    required this.alpha,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(center, size.width * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant BlurredCirclePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.alpha != alpha ||
        oldDelegate.color != color;
  }
}
