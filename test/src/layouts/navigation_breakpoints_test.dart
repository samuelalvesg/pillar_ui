import 'package:flutter_test/flutter_test.dart';
import 'package:pillar_ui/src/layouts/navigation_breakpoints.dart';

bool _rail(double w, double h, {bool was = false}) =>
    decideNavRail(width: w, height: h, breakpoint: 600, wasRail: was);

void main() {
  group('decideNavRail', () {
    test('width decides at the breakpoint', () {
      expect(_rail(599, 900), isFalse);
      expect(_rail(600, 900), isTrue);
    });

    test('hysteresis only applies leaving the rail', () {
      expect(_rail(585, 900, was: true), isTrue);
      expect(_rail(579, 900, was: true), isFalse);
      expect(_rail(585, 900), isFalse);
    });

    test('low landscape uses the rail from 480 dp wide', () {
      expect(_rail(500, 300), isTrue);
      expect(_rail(479, 300), isFalse);
    });

    test('portrait or tall windows never use the compact-height rule', () {
      expect(_rail(500, 900), isFalse);
      expect(_rail(300, 500), isFalse);
    });

    test('compact-height rule has its own hysteresis', () {
      expect(_rail(500, 490, was: true), isTrue);
      expect(_rail(500, 490), isFalse);
      expect(_rail(500, 505, was: true), isFalse);
    });
  });
}
