import 'package:flutter/material.dart';

///If [wrapWhen] is true, [child] is wrapped with [wrapWith]
class ConditionalParent extends StatefulWidget {
  final bool wrapWhen;
  final Widget child;
  final Widget Function(BuildContext context, Widget child) wrapWith;
  final Widget Function(BuildContext context, Widget child) alternativeWrapWith;

  const ConditionalParent({
    super.key,
    required this.wrapWith,
    this.alternativeWrapWith = _childIdentity,
    required this.child,
    required this.wrapWhen,
  });

  static Widget _childIdentity(BuildContext context, Widget child) => child;

  @override
  State<ConditionalParent> createState() => _ConditionalParentState();
}

class _ConditionalParentState extends State<ConditionalParent> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.wrapWhen) {
      return widget.wrapWith(
        context,
        Builder(
          key: _key,
          builder: (context) {
            return widget.child;
          },
        ),
      );
    } else {
      return widget.alternativeWrapWith(
        context,
        Builder(
          key: _key,
          builder: (context) {
            return widget.child;
          },
        ),
      );
    }
  }
}
