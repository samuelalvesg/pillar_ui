/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
/// 
/// Arquivo: adaptive_navigation_scaffold.dart
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Permite arrastar com MOUSE pra rolar (achado real, 2026-07-27) - o
/// `ScrollBehavior` padrão do Flutter só aceita drag por toque/caneta, não
/// mouse, em Web/Desktop. Sem isso, `ScrollableBottomNavBar` (abaixo) rola
/// certinho no celular mas parece "quebrada" no navegador/desktop - os
/// itens que não cabem ficam inacessíveis, sem barra de rolagem visível
/// nem jeito de arrastar com o mouse pra alcançar.
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class AdaptiveNavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  const AdaptiveNavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class AdaptiveNavigationScaffold extends StatelessWidget {
  final List<AdaptiveNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget? floatingActionButton;
  final String? title;
  final List<Widget>? actions;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    this.floatingActionButton,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isLandscape ? _buildLandscapeLayout(context) : _buildPortraitLayout(context),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Scaffold(
      key: const ValueKey('landscape'),
      appBar: title != null || actions != null
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: Row(
        children: [
          // Mesmo achado/fix de `ShellNavigationScaffold` (2026-08-07) -
          // `NavigationRail` não rola sozinho quando os itens não cabem na
          // altura disponível. `LayoutBuilder` + `ConstrainedBox(minHeight)`
          // restaura o comportamento original (Rail esticado do topo ao
          // fim, achado real do usuário logo após o 1º fix - `IntrinsicHeight`
          // sozinho tirava o "esticar" e deixava o Rail centralizado/curto)
          // e ainda rola quando o conteúdo realmente não cabe.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: onIndexChanged,
                    labelType: NavigationRailLabelType.all,
                    // Ativa o visual Material 3 no Rail
                    useIndicator: true,
                    indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
                    destinations: items
                        .map((item) => NavigationRailDestination(
                              icon: Tooltip(
                                message: item.label,
                                child: Icon(item.icon),
                              ),
                              label: Text(item.label),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildAnimatedContent(),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Scaffold(
      key: const ValueKey('portrait'),
      appBar: title != null || actions != null
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: _buildAnimatedContent(),
      bottomNavigationBar: ScrollableBottomNavBar(
        items: items,
        currentIndex: currentIndex,
        onIndexChanged: onIndexChanged,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildAnimatedContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: items[currentIndex].screen,
      ),
    );
  }
}

/// Shell de Navegação diretamente integrada ao GoRouter StatefulShellRoute.
/// Usa [navigationShell] como corpo gerenciado pelo roteador.
class ShellNavigationScaffold extends StatelessWidget {
  final Widget navigationShell;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<AdaptiveNavigationItem> items;

  const ShellNavigationScaffold({
    super.key,
    required this.navigationShell,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
  });

  static const _duracaoTransicao = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    // Achado real (2026-08-07, pedido do usuário): a troca landscape/
    // portrait não tinha NENHUMA animação (corte seco, `if`/`return`
    // direto pra 2 `Scaffold`s diferentes). Não dá pra simplesmente
    // envolver tudo num `AnimatedSwitcher` (como a classe irmã
    // `AdaptiveNavigationScaffold` faz) - ele manteria as 2 árvores
    // montadas ao mesmo tempo durante o crossfade, e `navigationShell` (o
    // Navigator interno do GoRouter, com chave própria persistente)
    // quebraria duplicado nas duas. Em vez disso, `navigationShell` fica
    // SEMPRE montado 1x só (`Expanded` fixo dentro do `Row`) - só o
    // "chrome" ao redor (Rail à esquerda, bottom nav embaixo) anima
    // tamanho/opacidade via `AnimatedSize`/`AnimatedOpacity`.
    return Scaffold(
      body: Row(
        children: [
          AnimatedSize(
            duration: _duracaoTransicao,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: _duracaoTransicao,
              opacity: isLandscape ? 1 : 0,
              child: isLandscape
                  // `LayoutBuilder` + `ConstrainedBox(minHeight)` (fix
                  // anterior, 2026-08-07) mantém o Rail esticado do topo
                  // ao fim quando cabe e rola quando não cabe.
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: currentIndex,
                              onDestinationSelected: onIndexChanged,
                              labelType: NavigationRailLabelType.all,
                              useIndicator: true,
                              indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
                              destinations: items
                                  .map((item) => NavigationRailDestination(
                                        icon: Icon(item.icon),
                                        label: Text(item.label),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          AnimatedSize(
            duration: _duracaoTransicao,
            curve: Curves.easeInOut,
            child: isLandscape
                ? const VerticalDivider(thickness: 1, width: 1)
                : const SizedBox.shrink(),
          ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: _duracaoTransicao,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: isLandscape
            ? const SizedBox.shrink()
            : ScrollableBottomNavBar(
                items: items,
                currentIndex: currentIndex,
                onIndexChanged: onIndexChanged,
              ),
      ),
    );
  }
}

/// Barra de navegação inferior rolável horizontalmente - substitui o
/// `NavigationBar` (Material 3) padrão, que divide a largura em partes
/// iguais entre TODOS os itens e fica ilegível/cortado com muitas abas
/// visíveis ao mesmo tempo (11 branches possíveis no shell principal,
/// achado real 2026-07-27). Cada item usa só a largura que precisa
/// (mínimo [_larguraItem]) e a barra rola se não couber tudo. Seleção
/// marcada preenchendo o retângulo inteiro do item (quadrado sólido),
/// não o indicador "pill" pequeno flutuante do `NavigationBar` padrão.
class ScrollableBottomNavBar extends StatefulWidget {
  const ScrollableBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  final List<AdaptiveNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  static const double _alturaBarra = 64;
  static const double _larguraItem = 84;

  /// Largura mínima pra caber ícone sozinho (sem texto) - abaixo disso nem
  /// ícone-só cabe pra todo mundo, aí sim rola.
  static const double _larguraItemSoIcone = 48;

  @override
  State<ScrollableBottomNavBar> createState() => _ScrollableBottomNavBarState();
}

class _ScrollableBottomNavBarState extends State<ScrollableBottomNavBar> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ScrollableBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _rolarParaSelecionado();
    }
  }

  /// Rola o item selecionado pra dentro da área visível - achado real
  /// (2026-07-27): mesmo com o drag de mouse liberado, se o item ativo
  /// começar fora da tela o usuário não tem pista nenhuma de que a barra
  /// rola, parece só "sumiu".
  void _rolarParaSelecionado() {
    if (!_scrollController.hasClients) return;
    final alvo = (widget.currentIndex * ScrollableBottomNavBar._larguraItem)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      alvo,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: ScrollableBottomNavBar._alturaBarra,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final n = widget.items.length;
              final larguraPorItem = n == 0
                  ? constraints.maxWidth
                  : constraints.maxWidth / n;

              // Cabe tudo com texto - estica preenchendo a tela (achado
              // real, 2026-07-27: pedido do usuário pra não ficar sempre
              // no modo compacto/rolável quando sobra espaço de verdade).
              if (larguraPorItem >= ScrollableBottomNavBar._larguraItem) {
                return Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _buildItem(
                          context,
                          widget.items[i],
                          i == widget.currentIndex,
                          () => widget.onIndexChanged(i),
                          mostrarTexto: true,
                        ),
                      ),
                  ],
                );
              }

              // Não cabe com texto, mas cabe só ícone - tira o texto e
              // ainda estica preenchendo a tela, sem precisar rolar.
              if (larguraPorItem >=
                  ScrollableBottomNavBar._larguraItemSoIcone) {
                return Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _buildItem(
                          context,
                          widget.items[i],
                          i == widget.currentIndex,
                          () => widget.onIndexChanged(i),
                          mostrarTexto: false,
                        ),
                      ),
                  ],
                );
              }

              // Nem ícone-só cabe pra todo mundo - último recurso, rola.
              // `Listener` captura o scroll da RODA do mouse (vertical por
              // natureza) e redireciona pro eixo horizontal - achado real
              // (2026-07-27): `dragDevices`/`ScrollConfiguration` só libera
              // arrastar clicando, não a rodinha; sem isso a rodinha do
              // mouse simplesmente não faz nada numa `ListView`/
              // `SingleChildScrollView` horizontal.
              return Listener(
                onPointerSignal: (event) {
                  if (event is! PointerScrollEvent) return;
                  if (!_scrollController.hasClients) return;
                  final alvo = (_scrollController.offset + event.scrollDelta.dy)
                      .clamp(0.0, _scrollController.position.maxScrollExtent);
                  _scrollController.jumpTo(alvo);
                },
                child: ScrollConfiguration(
                  behavior: _MouseDragScrollBehavior(),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < n; i++)
                          SizedBox(
                            width: ScrollableBottomNavBar._larguraItem,
                            child: _buildItem(
                              context,
                              widget.items[i],
                              i == widget.currentIndex,
                              () => widget.onIndexChanged(i),
                              mostrarTexto: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    AdaptiveNavigationItem item,
    bool selecionado,
    VoidCallback onTap, {
    required bool mostrarTexto,
  }) {
    final theme = Theme.of(context);
    final corConteudo = selecionado
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;

    // Sem `width` fixo aqui - quem chama decide: `Expanded` (modo
    // esticado, cabe tudo) preenche o espaço disponível sozinho; modo
    // rolável (abaixo) envolve com `SizedBox(width: _larguraItem)`.
    //
    // Indicador "pill" ao redor só do ícone (achado real, 2026-07-27,
    // pedido do usuário: horizontal era quadrado sólido preenchendo o item
    // inteiro, vertical (`NavigationRail`, `useIndicator: true`) já usava o
    // "pill" padrão Material 3 - inconsistente entre os 2. Padronizado
    // pro mesmo visual do Rail.
    final conteudo = SizedBox(
      height: ScrollableBottomNavBar._alturaBarra,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selecionado
                  ? theme.colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: corConteudo),
          ),
          if (mostrarTexto) ...[
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(fontSize: 11, color: corConteudo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Tooltip (hover no desktop/web, long-press no touch) - mais importante
    // ainda quando `mostrarTexto: false` (modo compacto ícone-só), mas
    // ajuda em qualquer modo.
    return Tooltip(
      message: item.label,
      child: InkWell(onTap: onTap, child: conteudo),
    );
  }
}
