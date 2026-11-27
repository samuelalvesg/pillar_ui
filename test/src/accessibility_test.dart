import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pillar_ui/pillar_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget home, {
  ThemeData? theme,
  TextScaler? scaler,
  bool noAnim = false,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler ?? TextScaler.noScaling,
        disableAnimations: noAnim,
      ),
      child: child!,
    ),
    home: home,
  );
}

const _items = [
  AdaptiveNavigationItem(icon: Icons.home, label: 'Home', screen: Text('s0')),
  AdaptiveNavigationItem(
    icon: Icons.search,
    label: 'Search',
    screen: Text('s1'),
  ),
  AdaptiveNavigationItem(
    icon: Icons.settings,
    label: 'Settings',
    screen: Text('s2'),
  ),
];

Widget _scaffold({
  int index = 0,
  ValueChanged<int>? onChanged,
  double? extendedAt,
  bool shortcuts = true,
}) => AdaptiveNavigationScaffold(
  items: _items,
  currentIndex: index,
  onIndexChanged: onChanged ?? (_) {},
  extendedRailBreakpoint: extendedAt,
  enableKeyboardShortcuts: shortcuts,
);

void main() {
  group('theme', () {
    test('light and dark share one seed path and the same scheme roles', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light, ColorScheme.fromSeed(seedColor: AppColors.primary));
    });

    test('text and status pairs reach 4.5:1 in both brightnesses', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final c = theme.colorScheme;
        final status = theme.extension<StatusColors>()!;
        final pairs = {
          'onSurface/surface': [c.onSurface, c.surface],
          'onSurfaceVariant/surfaceContainer': [
            c.onSurfaceVariant,
            c.surfaceContainer,
          ],
          'onPrimary/primary': [c.onPrimary, c.primary],
          'onErrorContainer/errorContainer': [
            c.onErrorContainer,
            c.errorContainer,
          ],
          'onSecondaryContainer/secondaryContainer': [
            c.onSecondaryContainer,
            c.secondaryContainer,
          ],
          'onSuccess/success': [status.onSuccess, status.success],
          'onWarning/warning': [status.onWarning, status.warning],
        };
        pairs.forEach((name, p) {
          expect(
            _contrast(p[0], p[1]),
            greaterThanOrEqualTo(4.5),
            reason: '$name in ${c.brightness}',
          );
        });
      }
    });

    test('extensions and fontFamily pass through to both themes', () {
      for (final theme in [
        AppTheme.light(extensions: [StatusColors.dark], fontFamily: 'Atkinson'),
        AppTheme.dark(extensions: [StatusColors.light], fontFamily: 'Atkinson'),
      ]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Atkinson');
        expect(theme.extension<StatusColors>(), isNotNull);
      }
    });

    test('text theme sets no fixed color', () {
      final t = AppTextTheme.build(headingFamily: 'H', bodyFamily: 'B');
      for (final s in [t.displayLarge, t.displayMedium, t.bodyMedium]) {
        expect(s?.color, isNull);
      }
      expect(t.displayLarge?.fontFamily, 'H');
      expect(t.bodyMedium?.fontFamily, 'B');
    });
  });

  group('ErrorContainerWidget', () {
    testWidgets('uses onErrorContainer and is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const ErrorContainerWidget(errorMessage: 'Boom')),
      );
      final scheme = AppTheme.light().colorScheme;
      expect(
        tester.widget<Text>(find.text('Boom')).style?.color,
        scheme.onErrorContainer,
      );
      expect(
        tester.getSemantics(find.byType(ErrorContainerWidget)),
        matchesSemantics(label: 'Boom', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('retry action appears only with callback and label', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        _app(
          const ErrorContainerWidget(errorMessage: 'x', retryLabel: 'Retry'),
        ),
      );
      expect(find.text('Retry'), findsNothing);
      await tester.pumpWidget(
        _app(
          ErrorContainerWidget(
            errorMessage: 'x',
            retryLabel: 'Retry',
            onRetry: () => retried++,
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('CollapsibleEdgeDrawer', () {
    Widget drawer({
      bool open = false,
      VoidCallback? onToggle,
      String? tip = 'Toggle panel',
      bool noAnim = false,
    }) => _app(
      Scaffold(
        body: Row(
          children: [
            CollapsibleEdgeDrawer(
              isOpen: open,
              onToggleOpen: onToggle ?? () {},
              toggleTooltip: tip,
              collapseTabKey: const Key('tab'),
              child: const Text('content'),
            ),
          ],
        ),
      ),
      noAnim: noAnim,
    );

    testWidgets('tab has a name, expanded state and a 48 dp target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(drawer(open: true));
      final node = tester.getSemantics(find.bySemanticsLabel('Toggle panel'));
      expect(
        node,
        isSemantics(
          label: 'Toggle panel',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('tab'))).width,
        greaterThanOrEqualTo(48),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus and Enter toggle it', (tester) async {
      var toggled = 0;
      await tester.pumpWidget(drawer(onToggle: () => toggled++));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(toggled, 1);
    });

    testWidgets('reduced motion opens without animating', (tester) async {
      await tester.pumpWidget(drawer(open: false, noAnim: true));
      await tester.pumpWidget(drawer(open: true, noAnim: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('content'), findsOneWidget);
    });
  });

  group('navigation scaffold', () {
    testWidgets('rail vs bottom bar follows width, not orientation', (
      tester,
    ) async {
      _size(tester, const Size(700, 300));
      await tester.pumpWidget(_app(_scaffold()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);

      _size(tester, const Size(800, 1200));
      await tester.pumpWidget(_app(_scaffold()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(ScrollableBottomNavBar), findsNothing);

      _size(tester, const Size(420, 300));
      await tester.pumpWidget(_app(_scaffold()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(ScrollableBottomNavBar), findsOneWidget);
    });

    testWidgets(
      'a phone held sideways (500x300) gets the rail to save height',
      (tester) async {
        _size(tester, const Size(500, 300));
        await tester.pumpWidget(_app(_scaffold()));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(ScrollableBottomNavBar), findsNothing);
      },
    );

    testWidgets(
      'hysteresis: the rail survives a small shrink, a fresh layout does not use it',
      (tester) async {
        _size(tester, const Size(700, 900));
        await tester.pumpWidget(_app(_scaffold()));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);

        _size(tester, const Size(590, 900));
        await tester.pumpWidget(_app(_scaffold()));
        await tester.pumpAndSettle();
        expect(
          find.byType(NavigationRail),
          findsOneWidget,
          reason: '590 is inside the 20 dp band',
        );

        _size(tester, const Size(570, 900));
        await tester.pumpWidget(_app(_scaffold()));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsNothing);

        _size(tester, const Size(590, 900));
        await tester.pumpWidget(_app(_scaffold()));
        await tester.pumpAndSettle();
        expect(
          find.byType(NavigationRail),
          findsNothing,
          reason: 'back up needs the full 600',
        );
      },
    );

    testWidgets('measures the space it has, not the window', (tester) async {
      _size(tester, const Size(1000, 900));
      await tester.pumpWidget(
        _app(
          Center(child: SizedBox(width: 500, height: 900, child: _scaffold())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(ScrollableBottomNavBar), findsOneWidget);
    });

    testWidgets('extended rail only from its breakpoint', (tester) async {
      _size(tester, const Size(1000, 700));
      await tester.pumpWidget(_app(_scaffold(extendedAt: 840)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );

      _size(tester, const Size(700, 700));
      await tester.pumpWidget(_app(_scaffold(extendedAt: 840)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
    });

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final mode = theme.colorScheme.brightness.name;

      testWidgets('selection is icon color only, bar ($mode)', (tester) async {
        _size(tester, const Size(400, 800));
        await tester.pumpWidget(_app(_scaffold(index: 1), theme: theme));
        await tester.pumpAndSettle();
        final scheme = theme.colorScheme;
        Color? colorOf(IconData icon) => tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(ScrollableBottomNavBar),
                matching: find.byIcon(icon),
              ),
            )
            .color;
        expect(colorOf(Icons.search), scheme.onSurface);
        expect(colorOf(Icons.home), isNot(scheme.onSurface));
        expect(
          colorOf(Icons.home),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.68),
            scheme.surfaceContainer,
          ),
        );
        final hasFill = find.descendant(
          of: find.byType(ScrollableBottomNavBar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                (w.decoration as dynamic) is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    scheme.secondaryContainer,
          ),
        );
        expect(hasFill, findsNothing);
      });

      testWidgets('selection is icon color only, rail ($mode)', (tester) async {
        _size(tester, const Size(900, 600));
        await tester.pumpWidget(_app(_scaffold(index: 1), theme: theme));
        await tester.pumpAndSettle();
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.useIndicator, isFalse);
        expect(rail.selectedIconTheme?.color, theme.colorScheme.onSurface);
        expect(
          rail.unselectedIconTheme?.color,
          isNot(theme.colorScheme.onSurface),
        );
      });

      testWidgets('label follows the icon color, bar and rail ($mode)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        final grey = Color.alphaBlend(
          scheme.onSurface.withValues(alpha: 0.68),
          scheme.surfaceContainer,
        );
        _size(tester, const Size(400, 800));
        await tester.pumpWidget(_app(_scaffold(index: 1), theme: theme));
        await tester.pumpAndSettle();
        Color? barLabel(String t) => tester
            .widget<Text>(
              find.descendant(
                of: find.byType(ScrollableBottomNavBar),
                matching: find.text(t),
              ),
            )
            .style
            ?.color;
        expect(barLabel('Search'), scheme.onSurface);
        expect(barLabel('Home'), grey);

        _size(tester, const Size(900, 600));
        await tester.pumpWidget(_app(_scaffold(index: 1), theme: theme));
        await tester.pumpAndSettle();
        Color? railLabel(String t) {
          final ctx = tester.element(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text(t),
            ),
          );
          return DefaultTextStyle.of(ctx).style.color;
        }

        expect(railLabel('Search'), scheme.onSurface);
        expect(railLabel('Home'), grey);
      });

      test('inactive grey is legible and dimmer than active ($mode)', () {
        final c = theme.colorScheme;
        final inactive = Color.alphaBlend(
          c.onSurface.withValues(alpha: 0.68),
          c.surfaceContainer,
        );
        expect(
          _contrast(inactive, c.surfaceContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(c.onSurface, inactive), greaterThanOrEqualTo(1.5));
      });
    }

    testWidgets('bottom bar item announces selected and a name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(_app(_scaffold(index: 1)));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        isSemantics(
          label: 'Search',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('200% text scale does not overflow the bottom bar', (
      tester,
    ) async {
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(_scaffold(), scaler: const TextScaler.linear(2.0)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final base = ScrollableBottomNavBar;
      expect(find.byType(base), findsOneWidget);
      expect(tester.getSize(find.byType(base)).height, greaterThan(64));
    });

    testWidgets('Alt+digit selects a destination', (tester) async {
      final picked = <int>[];
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(_app(_scaffold(onChanged: picked.add)));
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(picked, [2]);
    });

    testWidgets('shortcuts can be turned off', (tester) async {
      final picked = <int>[];
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(_scaffold(onChanged: picked.add, shortcuts: false)),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(picked, isEmpty);
    });

    testWidgets('Tab reaches the bar, arrows move, Enter activates', (
      tester,
    ) async {
      final picked = <int>[];
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(_app(_scaffold(onChanged: picked.add)));
      await tester.pumpAndSettle();
      // Content has no focusable widget, so the first Tab lands on the bar.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, [1]);
    });
  });

  group('shell keyboard and bar visibility', () {
    Widget shell({
      int index = 0,
      required ValueChanged<int> onChanged,
      NavigationShortcutModifier modifier = NavigationShortcutModifier.alt,
      bool barVisible = true,
    }) => ShellNavigationScaffold(
      navigationShell: const Text('shell'),
      items: _items,
      currentIndex: index,
      onIndexChanged: onChanged,
      shortcutModifier: modifier,
      bottomBarVisible: barVisible,
    );

    Future<void> chord(
      WidgetTester tester,
      LogicalKeyboardKey mod,
      LogicalKeyboardKey key, {
      bool shift = false,
    }) async {
      await tester.sendKeyDownEvent(mod);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(key);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(mod);
      await tester.pump();
    }

    testWidgets('Ctrl+Tab cycles and wraps, Ctrl+Shift+Tab goes back', (
      tester,
    ) async {
      var index = 0;
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => shell(
              index: index,
              onChanged: (i) => setState(() => index = i),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ctrl = LogicalKeyboardKey.controlLeft;
      await chord(tester, ctrl, LogicalKeyboardKey.tab);
      expect(index, 1);
      await chord(tester, ctrl, LogicalKeyboardKey.tab);
      await chord(tester, ctrl, LogicalKeyboardKey.tab);
      expect(index, 0, reason: 'wraps after the last destination');
      await chord(tester, ctrl, LogicalKeyboardKey.tab, shift: true);
      expect(index, 2, reason: 'wraps backwards');
    });

    testWidgets('control modifier: Ctrl+2 jumps, Alt+2 does not', (
      tester,
    ) async {
      final picked = <int>[];
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(
          shell(
            onChanged: picked.add,
            modifier: NavigationShortcutModifier.control,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chord(
        tester,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.digit2,
      );
      expect(picked, isEmpty);
      await chord(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.digit2,
      );
      expect(picked, [1]);
    });

    testWidgets('bottomBarVisible: false collapses the bar, rail ignores it', (
      tester,
    ) async {
      _size(tester, const Size(400, 800));
      await tester.pumpWidget(
        _app(shell(onChanged: (_) {}, barVisible: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScrollableBottomNavBar), findsNothing);

      await tester.pumpWidget(_app(shell(onChanged: (_) {})));
      await tester.pumpAndSettle();
      expect(find.byType(ScrollableBottomNavBar), findsOneWidget);

      _size(tester, const Size(900, 600));
      await tester.pumpWidget(
        _app(shell(onChanged: (_) {}, barVisible: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('ShellNavigationScaffold shares the same behavior', () {
    Widget shell({ValueChanged<int>? onChanged}) => ShellNavigationScaffold(
      navigationShell: const Text('shell'),
      items: _items,
      currentIndex: 1,
      onIndexChanged: onChanged ?? (_) {},
    );

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final mode = theme.colorScheme.brightness.name;

      testWidgets('bar and rail color active and inactive alike ($mode)', (
        tester,
      ) async {
        final scheme = theme.colorScheme;
        _size(tester, const Size(400, 800));
        await tester.pumpWidget(_app(shell(), theme: theme));
        await tester.pumpAndSettle();
        Color? barIcon(IconData i) => tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(ScrollableBottomNavBar),
                matching: find.byIcon(i),
              ),
            )
            .color;
        expect(barIcon(Icons.search), scheme.onSurface);
        expect(barIcon(Icons.home), isNot(scheme.onSurface));

        _size(tester, const Size(900, 600));
        await tester.pumpWidget(_app(shell(), theme: theme));
        await tester.pumpAndSettle();
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.useIndicator, isFalse);
        expect(rail.selectedIconTheme?.color, scheme.onSurface);
      });
    }

    testWidgets('width breakpoint and Alt+digit work', (tester) async {
      final picked = <int>[];
      _size(tester, const Size(800, 1200));
      await tester.pumpWidget(_app(shell(onChanged: picked.add)));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(picked, [0]);
    });
  });
}
