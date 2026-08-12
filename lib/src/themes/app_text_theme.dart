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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Opcional, mas comum

class AppTextTheme {
  static TextTheme get textTheme {
    return TextTheme(
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
        // Não defina 'color' aqui! Deixe o Theme gerenciar para o Dark Mode funcionar.
      ),

      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors
            .black, // O Flutter vai ajustar isso no dark mode se usarmos ColorScheme
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      // Adicione outros estilos conforme a necessidade do design
    );
  }
}