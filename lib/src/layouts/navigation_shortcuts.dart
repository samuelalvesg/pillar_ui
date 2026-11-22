import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Modifier key of the "jump to destination N" shortcuts.
enum NavigationShortcutModifier {
  /// Alt+1 .. Alt+9. Works inside browsers, which keep Ctrl+digit for their
  /// own tabs.
  alt,

  /// Ctrl+1 .. Ctrl+9. The desktop-app convention.
  control,
}

/// Keyboard navigation of the shell: Ctrl+Tab / Ctrl+Shift+Tab cycle through
/// the destinations (wrapping), and `modifier`+1..9 jump straight to one.
/// Also gives the shell a reading-order focus group, so Tab walks the visible
/// screen top to bottom and then the navigation.
///
/// Focus held inside a screen that is being hidden would be lost; after a
/// shortcut the shell's own scope takes it, which keeps the shortcuts working
/// (key events only reach shortcuts above a focused node) and makes the next
/// Tab press start from the newly shown screen.
class NavShortcuts extends StatefulWidget {
  const NavShortcuts({
    super.key,
    required this.enabled,
    required this.modifier,
    required this.currentIndex,
    required this.itemCount,
    required this.onIndexChanged,
    required this.child,
  });

  final bool enabled;
  final NavigationShortcutModifier modifier;
  final int currentIndex;
  final int itemCount;
  final ValueChanged<int> onIndexChanged;
  final Widget child;

  @override
  State<NavShortcuts> createState() => NavShortcutsState();
}

class NavShortcutsState extends State<NavShortcuts> {
  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  final _scope = FocusScopeNode(debugLabel: 'NavShortcuts');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _select(int index) {
    _scope.requestFocus();
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.itemCount == 0) return widget.child;
    final count = widget.itemCount;
    final current = widget.currentIndex;
    final alt = widget.modifier == NavigationShortcutModifier.alt;
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.tab, control: true): () =>
            _select((current + 1) % count),
        SingleActivator(
          LogicalKeyboardKey.tab,
          control: true,
          shift: true,
        ): () =>
            _select((current - 1 + count) % count),
        for (var i = 0; i < count && i < _digits.length; i++)
          SingleActivator(_digits[i], alt: alt, control: !alt): () =>
              _select(i),
      },
      child: FocusScope(
        node: _scope,
        autofocus: true,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: widget.child,
        ),
      ),
    );
  }
}
