/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: pillar_ui_test.dart
/// Módulo: Packages / UI
/// Descrição: Teste de widget do ErrorContainerWidget - garante que a
///            mensagem de erro passada é renderizada na tela.
///
/// Autor: Equipe Symmetris
/// Criado: 25/04/2026
/// Última Modificação: 14/07/2026
///
/// Dependências:
///   - pillar_ui (ErrorContainerWidget)
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
  testWidgets(
    'ErrorContainerWidget mostra a mensagem de erro e o ícone',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorContainerWidget(errorMessage: 'Falha ao carregar dados'),
          ),
        ),
      );

      expect(find.text('Falha ao carregar dados'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    },
  );
}
