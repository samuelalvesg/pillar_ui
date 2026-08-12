/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
/// 
/// Arquivo: deferred_widget.dart
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

class DeferredWidget extends StatefulWidget {
  final Future<void> Function() loader;
  final Widget Function() builder;

  const DeferredWidget({
    super.key,
    required this.loader,
    required this.builder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  Future<void>? _future;

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento da biblioteca assim que o widget entra na árvore
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.builder();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()), // Tela de loading
        );
      },
    );
  }
}