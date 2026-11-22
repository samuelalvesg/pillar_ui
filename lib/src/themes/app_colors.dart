/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: app_colors.dart
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

class AppColors {
  /// Brand seed shared by the light and dark themes.
  static const Color primary = Color(0xFF006874);

  @Deprecated('Use AppColors.primary; both themes share one seed.')
  static const Color primaryLight = primary;

  static const Color secondary = Color(0xFF625B71);
  static const Color tertiary = Color(0xFF7D5260);

  @Deprecated('Use StatusColors.of(context).success (has an on-color pair).')
  static const Color success = Color(0xFF28A745);
  @Deprecated('Use StatusColors.of(context).warning (has an on-color pair).')
  static const Color warning = Color(0xFFFFC107);
  @Deprecated('Use Theme.of(context).colorScheme.error.')
  static const Color danger = Color(0xFFDC3545);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
