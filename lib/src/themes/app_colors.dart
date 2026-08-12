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

import 'package:flutter/material.dart';

class AppColors {
  // Seed único de marca (2026-08-07, pedido do usuário: botões com cor
  // inconsistente entre claro/escuro - achado real, `primary` era o roxo
  // padrão do Material 3/Flutter (`0xFF6750A4`, o mesmo de qualquer
  // projeto novo sem customização), só `primaryLight` tinha sido trocado
  // pro teal de marca (2026-07-30). Agora os 2 temas usam o mesmo seed -
  // só muda `brightness` em `AppTheme`, não a cor.
  static const Color primary = Color(0xFF006874);
  static const Color primaryLight = Color(0xFF006874);

  static const Color secondary = Color(0xFF625B71);
  static const Color tertiary = Color(0xFF7D5260);

  // Cores Semânticas
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);

  // Cores Neutras (Corrigidas)
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}