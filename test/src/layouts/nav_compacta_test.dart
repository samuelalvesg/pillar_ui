/// Cobre `navLabelFontSize` e `navRailMinWidth` do
/// `AdaptiveNavigationScaffold` (barra principal mais compacta, pedido do
/// usuário 2026-09-24): o padrão (sem parâmetro) não muda, com parâmetro o
/// label da barra inferior e a largura do Rail mudam.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillar_ui/pillar_ui.dart';

AdaptiveNavigationScaffold _scaffold({
  double? navLabelFontSize,
  double? navRailMinWidth,
}) {
  return AdaptiveNavigationScaffold(
    currentIndex: 0,
    onIndexChanged: (_) {},
    navLabelFontSize: navLabelFontSize,
    navRailMinWidth: navRailMinWidth,
    items: const [
      AdaptiveNavigationItem(
        icon: Icons.home,
        label: 'Início',
        screen: SizedBox.shrink(),
      ),
      AdaptiveNavigationItem(
        icon: Icons.settings,
        label: 'Ajustes',
        screen: SizedBox.shrink(),
      ),
    ],
  );
}

void _tela(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('barra inferior: label 11 por padrão', (tester) async {
    _tela(tester, const Size(400, 800));
    await tester.pumpWidget(MaterialApp(home: _scaffold()));

    final texto = tester.widget<Text>(find.text('Início'));
    expect(texto.style?.fontSize, 11);
  });

  testWidgets('barra inferior: navLabelFontSize muda o label', (tester) async {
    _tela(tester, const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp(home: _scaffold(navLabelFontSize: 10)),
    );

    final texto = tester.widget<Text>(find.text('Início'));
    expect(texto.style?.fontSize, 10);
  });

  testWidgets('rail: navRailMinWidth estreita o Rail', (tester) async {
    _tela(tester, const Size(800, 400));
    await tester.pumpWidget(
      MaterialApp(home: _scaffold(navRailMinWidth: 60, navLabelFontSize: 10)),
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.minWidth, 60);
    final texto = tester.widget<Text>(find.text('Início'));
    expect(texto.style?.fontSize, 10);
  });
}
