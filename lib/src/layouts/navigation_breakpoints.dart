import 'package:material_ui/material_ui.dart';

/// Material "medium" window class starts at 600 dp: from there navigation is
/// a rail, below it a bottom bar. Decided by width, never by orientation.
const double kDefaultRailBreakpoint = 600;

bool showNavRail(BuildContext context, double breakpoint) =>
    MediaQuery.sizeOf(context).width >= breakpoint;

bool showExtendedNavRail(BuildContext context, double? breakpoint) =>
    breakpoint != null && MediaQuery.sizeOf(context).width >= breakpoint;
