import 'package:material_ui/material_ui.dart';

import '../themes/app_motion.dart';
import 'navigation_breakpoints.dart';
import 'navigation_chrome.dart';
import 'navigation_item.dart';
import 'navigation_shortcuts.dart';
import 'scrollable_bottom_nav_bar.dart';

/// Shell de Navegação diretamente integrada ao GoRouter StatefulShellRoute.
/// Usa [navigationShell] como corpo gerenciado pelo roteador.
class ShellNavigationScaffold extends StatelessWidget {
  final Widget navigationShell;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<AdaptiveNavigationItem> items;

  /// Mesmo significado de `AdaptiveNavigationScaffold.navBarHeight`/
  /// `navBarIconPadding`/`navBarLabelGap`/`navRailLabelMaxWidth` - `null`
  /// preserva o comportamento original.
  final double? navBarHeight;
  final double? navBarIconPadding;
  final double? navBarLabelGap;
  final double? navRailLabelMaxWidth;
  final double? navLabelFontSize;
  final double? navRailMinWidth;

  /// Window width (dp) from which the rail replaces the bottom bar.
  final double railBreakpoint;

  /// Window width (dp) from which the rail shows icon and label side by
  /// side. `null` (default) keeps the narrow rail at every width.
  final double? extendedRailBreakpoint;

  /// Ctrl+Tab / Ctrl+Shift+Tab cycle the destinations and
  /// [shortcutModifier]+1..9 jump to one of the first nine.
  final bool enableKeyboardShortcuts;

  /// Modifier of the jump-to-destination shortcuts.
  final NavigationShortcutModifier shortcutModifier;

  /// `false` collapses the bottom bar (for example while reading, in sync
  /// with a header that hides). Ignored when the rail is showing.
  final bool bottomBarVisible;

  const ShellNavigationScaffold({
    super.key,
    required this.navigationShell,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    this.navBarHeight,
    this.navBarIconPadding,
    this.navBarLabelGap,
    this.navRailLabelMaxWidth,
    this.navLabelFontSize,
    this.navRailMinWidth,
    this.railBreakpoint = kDefaultRailBreakpoint,
    this.extendedRailBreakpoint,
    this.enableKeyboardShortcuts = true,
    this.shortcutModifier = NavigationShortcutModifier.alt,
    this.bottomBarVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.duration(context, AppMotion.medium);

    // `navigationShell` (the router's navigator) is mounted once, always:
    // only the chrome around it animates. See [NavBody].
    return NavLayout(
      breakpoint: railBreakpoint,
      builder: (context, showRail) => NavShortcuts(
        enabled: enableKeyboardShortcuts,
        modifier: shortcutModifier,
        currentIndex: currentIndex,
        itemCount: items.length,
        onIndexChanged: onIndexChanged,
        child: Scaffold(
          body: NavBody(
            showRail: showRail,
            duration: dur,
            rail: NavRail(
              items: items,
              selectedIndex: currentIndex,
              onSelected: onIndexChanged,
              extendedBreakpoint: extendedRailBreakpoint,
              minWidth: navRailMinWidth,
              labelMaxWidth: navRailLabelMaxWidth,
              labelFontSize: navLabelFontSize,
            ),
            content: navigationShell,
          ),
          bottomNavigationBar: BottomBarSlot(
            showRail: showRail,
            visible: bottomBarVisible,
            duration: dur,
            bar: ScrollableBottomNavBar(
              items: items,
              currentIndex: currentIndex,
              onIndexChanged: onIndexChanged,
              barHeight: navBarHeight,
              iconPadding: navBarIconPadding,
              labelGap: navBarLabelGap,
              labelFontSize: navLabelFontSize,
            ),
          ),
        ),
      ),
    );
  }
}
