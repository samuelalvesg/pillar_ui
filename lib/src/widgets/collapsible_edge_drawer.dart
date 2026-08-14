/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: collapsible_edge_drawer.dart
/// Módulo: Packages / UI
/// Descrição:
///
/// Autor: Equipe Symmetris
/// Criado: 14/08/2026
/// Última Modificação: 14/08/2026
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

/// De qual borda o [CollapsibleEdgeDrawer] nasce - espelha a ordem
/// dos filhos do `Row` interno (conteúdo/aba/divisor).
enum DrawerSide { left, right }

/// Painel lateral colapsável - abre/fecha com `AnimatedSize`, sempre
/// com 1 aba fina de borda visível (aberto ou fechado) pra alternar.
/// Extraído do `PaSleevePanel` (sound_mixer_ui, achado do bundle
/// oficial da mesa - `SlideOut`) pra virar reusável entre telas/apps -
/// widget "burro", todo estado (aberto/fechado) mora em quem chama.
class CollapsibleEdgeDrawer extends StatelessWidget {
  const CollapsibleEdgeDrawer({
    super.key,
    required this.isOpen,
    required this.onToggleOpen,
    required this.child,
    this.side = DrawerSide.left,
    this.width = 200,
    // 40 (não 20) - achado real do usuário (2026-08-14): "sleeves são
    // muito pequenas pra serem clicadas, ou touch" - alvo de toque
    // mínimo recomendado (~44px Material/iOS), 20px ficava bem abaixo
    // disso.
    this.tabWidth = 40,
    this.showDivider = true,
    this.collapseTabKey,
  });

  final bool isOpen;
  final VoidCallback onToggleOpen;

  /// Conteúdo do painel quando aberto - some (`SizedBox(width: 0)`) em
  /// vez de só ficar invisível quando fechado, senão continuaria
  /// recebendo toque/participando do layout.
  final Widget child;

  final DrawerSide side;
  final double width;
  final double tabWidth;

  /// `false` esconde o `VerticalDivider` da borda - útil quando quem
  /// chama já tem outra divisória logo depois (evita 2 linhas juntas).
  final bool showDivider;

  final Key? collapseTabKey;

  @override
  Widget build(BuildContext context) {
    final content = ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        alignment: side == DrawerSide.left
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: isOpen ? SizedBox(width: width, child: child) : const SizedBox(width: 0),
      ),
    );
    final tab = _CollapseTab(
      key: collapseTabKey,
      isOpen: isOpen,
      side: side,
      width: tabWidth,
      onTap: onToggleOpen,
    );
    final divider = showDivider ? const VerticalDivider(width: 1) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: side == DrawerSide.left
          ? [content, tab, ?divider]
          : [?divider, tab, content],
    );
  }
}

class _CollapseTab extends StatelessWidget {
  const _CollapseTab({
    super.key,
    required this.isOpen,
    required this.side,
    required this.width,
    required this.onTap,
  });

  final bool isOpen;
  final DrawerSide side;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Esquerda: aberto aponta pra esquerda (fechar), fechado aponta
    // pra direita (abrir, revela conteúdo à direita da aba). Direita:
    // o inverso.
    final openIcon = side == DrawerSide.left
        ? Icons.chevron_left
        : Icons.chevron_right;
    final closedIcon = side == DrawerSide.left
        ? Icons.chevron_right
        : Icons.chevron_left;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Icon(isOpen ? openIcon : closedIcon, size: 16),
      ),
    );
  }
}
