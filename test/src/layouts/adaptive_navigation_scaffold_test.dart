/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: adaptive_navigation_scaffold_test.dart
/// Módulo: Packages / UI
/// Descrição: Cobre o slot `titleWidget` novo do
///            `AdaptiveNavigationScaffold` (2026-08-13, pedido de
///            reaproveitamento de uma barra de título rica acima de
///            todas as abas) - `titleWidget` vence sobre `title`
///            quando os dois existem, e `title` sozinho continua
///            funcionando como antes (regressão).
///
/// Autor: Equipe Symmetris
/// Criado: 2026-08-13
/// Última Modificação: 2026-08-13
///
/// Dependências:
///   - pillar_ui (AdaptiveNavigationScaffold)
///
/// Premissas:
///   ✅
///
/// Edge Cases Conhecidos:
///   ⚠️
/// ==============================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillar_ui/pillar_ui.dart';

void main() {
  AdaptiveNavigationScaffold buildScaffold({String? title, Widget? titleWidget}) {
    return AdaptiveNavigationScaffold(
      currentIndex: 0,
      onIndexChanged: (_) {},
      title: title,
      titleWidget: titleWidget,
      items: const [
        AdaptiveNavigationItem(
          icon: Icons.home,
          label: 'Início',
          screen: SizedBox.shrink(),
        ),
      ],
    );
  }

  for (final size in [const Size(400, 800), const Size(800, 400)]) {
    final orientation = size.width > size.height ? 'paisagem' : 'retrato';

    testWidgets(
      'titleWidget renderiza no lugar de title ($orientation)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: buildScaffold(
              title: 'Título simples',
              titleWidget: const Text('Barra rica'),
            ),
          ),
        );

        expect(find.text('Barra rica'), findsOneWidget);
        expect(find.text('Título simples'), findsNothing);
      },
    );

    testWidgets(
      'title sozinho continua funcionando ($orientation)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(home: buildScaffold(title: 'Título simples')),
        );

        expect(find.text('Título simples'), findsOneWidget);
      },
    );
  }
}
