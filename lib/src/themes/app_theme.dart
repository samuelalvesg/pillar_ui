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
  /// [extensions] are added next to [StatusColors] (for example a host
  /// library's own theme extensions); [fontFamily] is the app's bundled font.
  static ThemeData light({
    Color seedColor = AppColors.primary,
    Iterable<ThemeExtension<dynamic>> extensions = const [],
    String? fontFamily,
  }) => _build(
    seedColor,
    Brightness.light,
    StatusColors.light,
    extensions,
    fontFamily,
  );

  static ThemeData dark({
    Color seedColor = AppColors.primary,
    Iterable<ThemeExtension<dynamic>> extensions = const [],
    String? fontFamily,
  }) => _build(
    seedColor,
    Brightness.dark,
    StatusColors.dark,
    extensions,
    fontFamily,
  );

  static ThemeData _build(
    Color seedColor,
    Brightness brightness,
    StatusColors status,
    Iterable<ThemeExtension<dynamic>> extensions,
    String? fontFamily,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      fontFamily: fontFamily,
      extensions: [status, ...extensions],
    );
  }
}
