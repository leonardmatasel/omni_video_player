import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

import 'custom_route_observer.dart';

/// A global instance of [GlobalRoutesObserver], currently used as a singleton.
/// Could be later moved to a provider or dependency injection system.
final globalRouteObserver = GlobalRoutesObserver();

/// A [NavigatorObserver] implementation that maintains a stack of all currently
/// opened routes.
///
/// This observer tracks the navigation stack by listening to route push and pop
/// events and updates an internal list accordingly. The current stack can be
/// retrieved as an immutable [BuiltList] via [routeStack].
class GlobalRoutesObserver extends CustomRouteObserver<Route> {
  final List<Route> _routeStack = [];

  /// Stack of the opened routes
  BuiltList<Route> get routeStack => _routeStack.toBuiltList();

  @override
  void didPop(Route route, Route? previousRoute) {
    _routeStack.removeLast();

    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _routeStack.add(route);

    super.didPush(route, previousRoute);
  }
}
