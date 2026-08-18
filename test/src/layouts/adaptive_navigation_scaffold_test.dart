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
  AdaptiveNavigationScaffold buildScaffold({
    String? title,
    Widget? titleWidget,
  }) {
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

  testWidgets(
    'trocar orientação NÃO duplica o conteúdo do item ativo (achado real '
    'do usuário, 2026-08-17: "troco a orientação -> clico em voltar, da '
    'erro sem log" - stack real era "multiple heroes share the same '
    'tag", causado pela versão antiga que envolvia o Scaffold INTEIRO '
    'num AnimatedSwitcher, montando as 2 árvores - retrato E paisagem - '
    'ao mesmo tempo durante o crossfade)',
    (tester) async {
      final scaffold = AdaptiveNavigationScaffold(
        currentIndex: 0,
        onIndexChanged: (_) {},
        items: const [
          AdaptiveNavigationItem(
            icon: Icons.home,
            label: 'Início',
            screen: FloatingActionButton(
              heroTag: 'fixed_tag',
              onPressed: null,
              child: Icon(Icons.add),
            ),
          ),
        ],
      );

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: scaffold));
      expect(find.byTooltip('fixed_tag'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Troca pra paisagem e bombeia frames NO MEIO da transição
      // (300ms, `_duracaoTransicaoChrome`) - é exatamente aí que a
      // versão antiga tinha as 2 árvores montadas juntas.
      tester.view.physicalSize = const Size(800, 400);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sem exceção de Hero duplicado E só 1 instância do FAB viva -
      // conteúdo nunca duplicou durante a transição.
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );

  for (final size in [const Size(400, 800), const Size(800, 400)]) {
    final orientation = size.width > size.height ? 'paisagem' : 'retrato';

    testWidgets('titleWidget renderiza no lugar de title ($orientation)', (
      tester,
    ) async {
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
    });

    testWidgets('title sozinho continua funcionando ($orientation)', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: buildScaffold(title: 'Título simples')),
      );

      expect(find.text('Título simples'), findsOneWidget);
    });
  }
}
