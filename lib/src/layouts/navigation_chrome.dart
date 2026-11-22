import 'package:material_ui/material_ui.dart';

import '../themes/app_motion.dart';
import 'navigation_breakpoints.dart';
import 'navigation_item.dart';

/// The rail both scaffolds share: scrolls when the destinations do not fit,
/// stretches to the full height when they do, and colors the active
/// destination by icon and label only (no indicator pill).
class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.extendedBreakpoint,
    this.leading,
    this.minWidth,
    this.labelMaxWidth,
    this.labelFontSize,
  });

  final List<AdaptiveNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? extendedBreakpoint;
  final Widget? leading;
  final double? minWidth;
  final double? labelMaxWidth;
  final double? labelFontSize;

  /// Without [labelMaxWidth] the label stays on one line and the rail widens
  /// to the longest one; with it the label wraps to two lines instead.
  Widget _label(String label) {
    final style = estiloRotuloDoRail(labelFontSize);
    final maxWidth = labelMaxWidth;
    if (maxWidth == null) return Text(label, style: style);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        label,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extended = showExtendedNavRail(context, extendedBreakpoint);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              // `NavigationRail` asserts on an out-of-range index; `null` is
              // how "no destination selected" is expressed (see
              // [AdaptiveNavigationScaffold.highlightIndex]).
              selectedIndex:
                  (selectedIndex >= 0 && selectedIndex < items.length)
                  ? selectedIndex
                  : null,
              onDestinationSelected: onSelected,
              leading: leading,
              minWidth: minWidth,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              useIndicator: false,
              selectedIconTheme: IconThemeData(
                color: navItemColor(scheme, true),
              ),
              unselectedIconTheme: IconThemeData(
                color: navItemColor(scheme, false),
              ),
              selectedLabelTextStyle: TextStyle(
                color: navItemColor(scheme, true),
              ),
              unselectedLabelTextStyle: TextStyle(
                color: navItemColor(scheme, false),
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: item.label,
                      child: navItemIcon(item),
                    ),
                    label: _label(item.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail + divider + content. The rail and divider animate in and out as
/// [showRail] flips; [content] stays mounted exactly once (a duplicated
/// subtree would duplicate `Hero` tags and the router's navigator).
class NavBody extends StatelessWidget {
  const NavBody({
    super.key,
    required this.showRail,
    required this.duration,
    required this.rail,
    required this.content,
  });

  final bool showRail;
  final Duration duration;
  final Widget rail;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSizeOrCut(
          duration: duration,
          curve: AppMotion.standard,
          child: AnimatedOpacity(
            duration: duration,
            opacity: showRail ? 1 : 0,
            child: showRail ? rail : const SizedBox.shrink(),
          ),
        ),
        AnimatedSizeOrCut(
          duration: duration,
          curve: AppMotion.standard,
          child: showRail
              ? const VerticalDivider(thickness: 1, width: 1)
              : const SizedBox.shrink(),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Slot of the bottom bar: it collapses when the rail takes over.
class BottomBarSlot extends StatelessWidget {
  const BottomBarSlot({
    super.key,
    required this.showRail,
    required this.visible,
    required this.duration,
    required this.bar,
  });

  final bool showRail;
  final bool visible;
  final Duration duration;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    return AnimatedSizeOrCut(
      duration: duration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: showRail || !visible ? const SizedBox.shrink() : bar,
    );
  }
}
