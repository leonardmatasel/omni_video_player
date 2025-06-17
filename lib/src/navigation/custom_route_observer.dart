import 'package:flutter/material.dart';

class CustomRouteObserver<R extends Route<dynamic>> extends NavigatorObserver {
  final Map<R, Set<CustomRouteAware>> _listeners = <R, Set<CustomRouteAware>>{};

  /// Subscribe [routeAware] to be informed about changes to [route].
  ///
  /// Going forward, [routeAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(CustomRouteAware routeAware, R route) {
    final subscribers = _listeners.putIfAbsent(
      route,
      () => <CustomRouteAware>{},
    );
    if (subscribers.add(routeAware)) {
      routeAware.didPush();
    }
  }

  /// Unsubscribe [routeAware].
  ///
  /// [routeAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.
  void unsubscribe(CustomRouteAware routeAware) {
    for (final route in _listeners.keys) {
      final subscribers = _listeners[route];
      subscribers?.remove(routeAware);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is R && previousRoute is R) {
      final previousSubscribers = _listeners[previousRoute]?.toList();

      if (previousSubscribers != null) {
        for (final routeAware in previousSubscribers) {
          routeAware.didPopNext(route);
        }
      }

      final subscribers = _listeners[route]?.toList();

      if (subscribers != null) {
        for (final routeAware in subscribers) {
          routeAware.didPop();
        }
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is R && previousRoute is R) {
      final previousSubscribers = _listeners[previousRoute];

      if (previousSubscribers != null) {
        for (final routeAware in previousSubscribers) {
          routeAware.didPushNext(route);
        }
      }
    }
  }
}

/// An interface for objects that are aware of their current [Route].
///
/// This is used with [RouteObserver] to make a widget aware of changes to the
/// [Navigator]'s session history.
abstract mixin class CustomRouteAware {
  /// Called when the top route has been popped off, and the current route
  /// shows up.
  void didPopNext(Route route) {}

  /// Called when the current route has been pushed.
  void didPush() {}

  /// Called when the current route has been popped off.
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  void didPushNext(Route route) {}
}
