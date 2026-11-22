/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: app_text_theme.dart
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

/// Text theme with titles and body in the font families the app supplies
/// (bundled by the app: the package fetches nothing at runtime). No color is
/// set here so the active `ColorScheme` (light or dark) decides it.
class AppTextTheme {
  static TextTheme build({String? headingFamily, String? bodyFamily}) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: headingFamily,
        fontSize: 40,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
