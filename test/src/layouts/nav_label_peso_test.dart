/// O rótulo da barra vertical (`NavigationRail`) e o da barra horizontal (inferior) precisam ter a MESMA
/// aparência. Achado do usuário (2026-09-25): o rail parecia em negrito e a barra inferior não, porque o
/// `NavigationRail` do Material usa `labelMedium` (peso 500) e o `TextStyle(fontSize:)` do app só era
/// mesclado com isso. Compara o peso EFETIVO desenhado (o `RenderParagraph`), não o `TextStyle` passado.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillar_ui/pillar_ui.dart';

const _itens = [
  AdaptiveNavigationItem(icon: Icons.home, label: 'Início', screen: SizedBox.shrink()),
  AdaptiveNavigationItem(icon: Icons.settings, label: 'Ajustes', screen: SizedBox.shrink()),
];

void _tela(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Weight and size that are really painted for the label [rotulo].
({FontWeight peso, double? tamanho}) _desenhado(WidgetTester tester, String rotulo) {
  final estilo = tester.renderObject<RenderParagraph>(find.text(rotulo)).text.style;
  return (peso: estilo?.fontWeight ?? FontWeight.w400, tamanho: estilo?.fontSize);
}

Widget _adaptive({double? fontSize, double? labelMaxWidth}) => MaterialApp(
  home: AdaptiveNavigationScaffold(
    currentIndex: 0,
    onIndexChanged: (_) {},
    navLabelFontSize: fontSize,
    navRailLabelMaxWidth: labelMaxWidth,
    items: _itens,
  ),
);

Widget _shell({double? fontSize, double? labelMaxWidth}) => MaterialApp(
  home: ShellNavigationScaffold(
    navigationShell: const SizedBox.shrink(),
    currentIndex: 0,
    onIndexChanged: (_) {},
    navLabelFontSize: fontSize,
    navRailLabelMaxWidth: labelMaxWidth,
    items: _itens,
  ),
);

void main() {
  group('estiloRotuloDoRail', () {
    test('peso normal e tamanho configurável', () {
      expect(estiloRotuloDoRail(10).fontWeight, FontWeight.w400);
      expect(estiloRotuloDoRail(10).fontSize, 10);
    });

    test('sem tamanho, mantém o padrão do Material (só fixa o peso)', () {
      expect(estiloRotuloDoRail(null).fontSize, isNull);
      expect(estiloRotuloDoRail(null).fontWeight, FontWeight.w400);
    });
  });

  for (final (nome, montar) in <(String, Widget Function({double? fontSize, double? labelMaxWidth}))>[
    ('AdaptiveNavigationScaffold', _adaptive),
    ('ShellNavigationScaffold', _shell),
  ]) {
    group(nome, () {
      testWidgets('rótulo do rail (vertical) tem o mesmo peso e tamanho do da barra inferior', (tester) async {
        _tela(tester, const Size(400, 800)); // portrait: barra inferior
        await tester.pumpWidget(montar(fontSize: 10));
        await tester.pumpAndSettle();
        final barra = _desenhado(tester, 'Início');

        _tela(tester, const Size(800, 400)); // landscape: rail
        await tester.pumpWidget(montar(fontSize: 10));
        await tester.pumpAndSettle();
        final rail = _desenhado(tester, 'Início');

        expect(rail.peso, barra.peso, reason: 'rail=${rail.peso} barra=${barra.peso}');
        expect(rail.peso, FontWeight.w400);
        expect(rail.tamanho, barra.tamanho);
      });

      testWidgets('o rótulo do rail continua com peso normal com largura máxima (2 linhas)', (tester) async {
        _tela(tester, const Size(800, 400));
        await tester.pumpWidget(montar(fontSize: 10, labelMaxWidth: 60));
        await tester.pumpAndSettle();

        expect(_desenhado(tester, 'Início').peso, FontWeight.w400);
      });

      testWidgets('sem navLabelFontSize o rail também fica com peso normal', (tester) async {
        _tela(tester, const Size(800, 400));
        await tester.pumpWidget(montar());
        await tester.pumpAndSettle();

        expect(_desenhado(tester, 'Início').peso, FontWeight.w400);
      });
    });
  }
}
