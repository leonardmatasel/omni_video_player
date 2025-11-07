import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

abstract class AccessibilityUtils {
  static void announce(String message) {
    if (isPlatformIOS) {
      // perché sto magheggio? Vedi https://github.com/flutter/flutter/issues/122101
      _announceTimer?.cancel();

      Future.delayed(Duration(seconds: 1), () {
        SemanticsService.announce(message, TextDirection.ltr);
        _announceTimer?.cancel();
        _announceTimer = null;
      });
    } else {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  static void announceExpansionChanged(BuildContext context, bool expanded) {
    final stateHint = expansionStateHint(context, expanded);
    announce(stateHint);
  }

  static String expansionStateHint(BuildContext context, bool expanded) =>
      // sì lo so, sembra sbagliato, ma collapsedHint contiene "Espanso" e viceversa
      expanded
      ? MaterialLocalizations.of(context).collapsedHint
      : MaterialLocalizations.of(context).expandedHint;

  /// Su iOS non serve il semantic label se c'è già un tooltip
  static String? semanticLabelFromTooltip(String? tooltip) =>
      isPlatformIOS ? null : tooltip;

  static Timer? _announceTimer;
}

bool get isPlatformIOS => !kIsWeb && Platform.isIOS;
