import 'package:material_ui/material_ui.dart';

/// Material "medium" window class starts at 600 dp: from there navigation is
/// a rail, below it a bottom bar. Decided by the width the scaffold really
/// has, never by the aspect ratio (it flips on every rotation or split).
const double kDefaultRailBreakpoint = 600;

/// dp the width (or height) must move past a limit, in the direction of the
/// current layout, before it flips. Keeps the bar from flickering while a
/// window is resized around 600 dp.
const double kRailHysteresis = 20;

/// Below this height, in landscape, a bottom bar eats too much of the screen
/// (a phone held sideways): the rail is used even under the width breakpoint.
const double kCompactHeight = 480;

/// The compact-height rule only applies from this width, so a tiny window
/// does not lose most of its width to a rail.
const double kCompactHeightMinWidth = 480;

/// Whether to show the rail for an area of [width] x [height] dp.
/// [wasRail] is the previous decision and drives the hysteresis.
bool decideNavRail({
  required double width,
  required double height,
  required double breakpoint,
  required bool wasRail,
  double hysteresis = kRailHysteresis,
  double compactHeight = kCompactHeight,
}) {
  final heightLimit = wasRail ? compactHeight + hysteresis : compactHeight;
  if (height < heightLimit &&
      width > height &&
      width >= kCompactHeightMinWidth) {
    return true;
  }
  return width >= (wasRail ? breakpoint - hysteresis : breakpoint);
}

/// Measures the space the navigation really has (its parent's constraints,
/// falling back to the window when unbounded) and hands [builder] the rail
/// decision, remembering the last one for the hysteresis.
class NavLayout extends StatefulWidget {
  const NavLayout({super.key, required this.breakpoint, required this.builder});

  final double breakpoint;
  final Widget Function(BuildContext context, bool showRail) builder;

  @override
  State<NavLayout> createState() => _NavLayoutState();
}

class _NavLayoutState extends State<NavLayout> {
  bool _showRail = false;

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : window.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : window.height;
        _showRail = decideNavRail(
          width: width,
          height: height,
          breakpoint: widget.breakpoint,
          wasRail: _showRail,
        );
        return widget.builder(context, _showRail);
      },
    );
  }
}

bool showExtendedNavRail(BuildContext context, double? breakpoint) =>
    breakpoint != null && MediaQuery.sizeOf(context).width >= breakpoint;
