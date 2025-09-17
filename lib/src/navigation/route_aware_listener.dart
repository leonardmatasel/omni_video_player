import 'package:flutter/material.dart';

import 'custom_route_observer.dart';
import 'global_routes_observer.dart';

/// A widget that listens to navigation route changes and triggers callbacks
/// when the route stack changes relative to this widget's route.
///
/// Useful for responding to navigation events such as:
/// - When the current route becomes visible again after popping another route (`onPopNext`).
/// - When the current route is popped (`onPop`).
/// - When a new route is pushed on top of the current route (`onPushNext`).
/// - When the current route is pushed onto the stack (`onPush`).
///
/// The widget subscribes to a global route observer to track these changes,
/// and automatically unsubscribes when disposed.
///
/// This widget is often used to pause/resume media playback or update UI state
/// based on navigation stack changes.
///
/// Example usage:
/// ```dart
/// RouteAwareListener(
///   onPopNext: (route) => resumePlayback(),
///   onPop: () => cleanup(),
///   child: YourWidget(),
/// )
/// ```
class RouteAwareListener extends StatefulWidget {
  /// Called when the top route has been popped off, and the current route shows up.
  final void Function(Route route)? onPopNext;

  /// Called when the current route has been popped off.
  final VoidCallback? onPop;

  /// Called when a new route has been pushed, and the current route is no longer visible.
  final void Function(Route route)? onPushNext;

  /// Called when the current route has been pushed.
  final VoidCallback? onPush;

  final Widget child;

  /// The route to listen to. By default uses ModalRoute.of(context)
  final Route? listenRoute;

  const RouteAwareListener({
    super.key,
    required this.child,
    this.onPopNext,
    this.onPop,
    this.onPushNext,
    this.onPush,
    this.listenRoute,
  });

  @override
  State<RouteAwareListener> createState() => RouteAwareListenerState();
}

class RouteAwareListenerState extends State<RouteAwareListener>
    with CustomRouteAware {
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      globalRouteObserver.subscribe(
        this,
        widget.listenRoute ?? ModalRoute.of(context)!,
      );
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    if (_subscribed) {
      globalRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext(Route route) {
    widget.onPopNext?.call(route);
  }

  @override
  void didPush() {
    widget.onPush?.call();
  }

  @override
  void didPop() {
    widget.onPop?.call();
  }

  @override
  void didPushNext(Route route) {
    widget.onPushNext?.call(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
