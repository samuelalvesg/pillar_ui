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

import 'package:material_ui/material_ui.dart';
import './app_colors.dart';
import './status_colors.dart';

class AppTheme {
  /// Both themes come from the same seed and the same code path; only the
  /// brightness differs. Each app brands with its own [seedColor].
  static ThemeData light({Color seedColor = AppColors.primary}) =>
      _build(seedColor, Brightness.light, StatusColors.light);

  static ThemeData dark({Color seedColor = AppColors.primary}) =>
      _build(seedColor, Brightness.dark, StatusColors.dark);

  static ThemeData _build(
    Color seedColor,
    Brightness brightness,
    StatusColors status,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      extensions: [status],
    );
  }
}
