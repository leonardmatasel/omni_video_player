import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final bool allowSeeking;
  final Color activeColor;
  final Color thumbColor;
  final Color inactiveColor;

  const ProgressBar({
    super.key,
    required this.value,
    required this.max,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.allowSeeking = true,
    required this.activeColor,
    required this.thumbColor,
    required this.inactiveColor,
  });

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  double? _dragValue;

  void _updateValue(Offset localPosition, BoxConstraints constraints) {
    double dx = localPosition.dx.clamp(0.0, constraints.maxWidth);
    double newValue = (dx / constraints.maxWidth) * widget.max;
    newValue = newValue.clamp(0, widget.max);
    if (widget.onChanged != null) widget.onChanged!(newValue);
    setState(() {
      _dragValue = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _dragValue ?? widget.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = 6.0;
        final thumbRadius = 10.0;
        final percent = (displayValue / widget.max).clamp(0.0, 1.0);
        final thumbX = (constraints.maxWidth * percent).clamp(
          thumbRadius,
          constraints.maxWidth - thumbRadius,
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: widget.allowSeeking
              ? (details) {
                  widget.onChangeStart?.call(_dragValue ?? widget.value);
                }
              : null,
          onHorizontalDragUpdate: widget.allowSeeking
              ? (details) {
                  _updateValue(details.localPosition, constraints);
                }
              : null,
          onHorizontalDragEnd: widget.allowSeeking
              ? (details) {
                  widget.onChangeEnd?.call(_dragValue ?? widget.value);
                  setState(() {
                    _dragValue = null;
                  });
                }
              : null,
          onTapDown: widget.allowSeeking
              ? (details) {
                  final tapPosition =
                      (details.localPosition.dx / constraints.maxWidth) *
                          widget.max;
                  final clampedTapPos =
                      tapPosition.clamp(0, widget.max).toDouble();
                  widget.onChangeStart?.call(clampedTapPos);
                  widget.onChanged?.call(clampedTapPos);
                  widget.onChangeEnd?.call(clampedTapPos);
                  setState(() {
                    _dragValue = null;
                  });
                }
              : null,
          child: SizedBox(
            height: 2 * thumbRadius,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track (background)
                Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: widget.inactiveColor,
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),

                // Active progress
                Container(
                  width: thumbX,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),

                // Thumb
                Positioned(
                  left: thumbX - thumbRadius,
                  child: Container(
                    width: 2 * thumbRadius,
                    height: 2 * thumbRadius,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 3,
                          color: Colors.black26,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
