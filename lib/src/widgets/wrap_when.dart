import 'package:flutter/material.dart';

class WrapWhen extends StatelessWidget {
  final bool condition;
  final Widget Function(Widget child) wrapper;
  final Widget child;

  const WrapWhen({
    super.key,
    required this.condition,
    required this.wrapper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? wrapper(child) : child;
  }
}
