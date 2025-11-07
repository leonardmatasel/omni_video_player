import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/src/utils/accessibility/accessibility_utils.dart';

class Accessible extends StatelessWidget {
  const Accessible({
    super.key,
    this.clickable,
    this.button,
    this.expanded,
    this.excludeSemantics,
    this.selected,
    this.hint,
    this.androidTapHint,
    this.androidLongPressHint,
    // aggiungere altri parametri utili
    required this.child,
  });

  /// Scorciatoia per creare un widget cliccabile senza usare un Button esplicito
  Accessible.clickable({
    super.key,
    bool explicitButton = false,
    this.expanded,
    this.selected,
    this.excludeSemantics,
    this.hint,
    this.androidTapHint,
    this.androidLongPressHint,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    BorderRadius? splashBorderRadius,
    required Widget child,
  }) : clickable = onTap != null || onLongPress != null,
       button = explicitButton ? true : null,
       child = InkWell(
         borderRadius: splashBorderRadius,
         onTap: onTap,
         onLongPress: onLongPress,
         child: child,
       );

  /// Su iOS identifica il widget come "button"
  final bool? clickable;

  /// Identifica il widget come "button" (sia Android che iOS)
  final bool? button;

  final bool? expanded;
  final bool? selected;
  final bool? excludeSemantics;

  final String? hint;
  final String? androidTapHint;
  final String? androidLongPressHint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: button ?? (isPlatformIOS ? clickable : null),
      selected: selected,
      hint: hint,
      // non usate su iOS, vedi https://api.flutter.dev/flutter/semantics/SemanticsHintOverrides-class.html
      onTapHint: androidTapHint,
      onLongPressHint: androidLongPressHint,
      // al momento expanded sembra non fare nulla (TalkBack e VoiceOver), quindi lo usiamo in "value"
      // expanded: expanded,
      value: expanded != null
          ? AccessibilityUtils.expansionStateHint(context, expanded!)
          : null,
      excludeSemantics: excludeSemantics ?? false,
      child: child,
    );
  }
}

bool get isPlatformIOS => !kIsWeb && Platform.isIOS;
