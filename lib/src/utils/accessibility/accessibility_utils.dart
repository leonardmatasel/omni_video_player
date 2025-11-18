import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AccessibilityUtils {
  static String expansionStateHint(BuildContext context, bool expanded) =>
      // sì lo so, sembra sbagliato, ma collapsedHint contiene "Espanso" e viceversa
      expanded
      ? MaterialLocalizations.of(context).collapsedHint
      : MaterialLocalizations.of(context).expandedHint;

  /// Su iOS non serve il semantic label se c'è già un tooltip
  static String? semanticLabelFromTooltip(String? tooltip) =>
      isPlatformIOS ? null : tooltip;
}

bool get isPlatformIOS => !kIsWeb && Platform.isIOS;
