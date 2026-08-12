/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
/// 
/// Arquivo: app_theme.dart
/// Módulo: Packages / UI
/// Descrição: 
/// 
/// Autor: Equipe Symmetris
/// Criado: 25/04/2026
/// Última Modificação: 25/04/2026
/// 
/// Dependências:
/// 
/// Premissas:
///   ✅ 
/// 
/// Edge Cases Conhecidos:
///   ⚠️ 
/// ==============================================

import 'package:flutter/material.dart';
import './app_colors.dart';

class AppTheme {
  // `seedColor` opcional (default = cor de marca do Symmetris,
  // `AppColors.primary`) - pacote extraído pra reuso entre apps
  // (`docs/BACKLOG.md` item 8.1 do Symmetris), cada app branda com a
  // própria cor sem precisar fazer fork do tema inteiro.
  static ThemeData light({Color seedColor = AppColors.primaryLight}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ).copyWith(
            //error: AppColors.danger,
            surface: Colors.grey[50],
          ),
    );
  }

  static ThemeData dark({Color seedColor = AppColors.primary}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: seedColor,
      // Adicione ajustes para o modo dark
    );
  }
}