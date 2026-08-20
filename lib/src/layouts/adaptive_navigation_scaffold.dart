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

  /// Título rico (widget qualquer, ex. uma barra de status persistente
  /// acima de todas as abas) - vence sobre [title] quando os dois são
  /// passados. Aditivo (não muda o tipo de [title] existente) - nenhum
  /// outro consumidor deste pacote no monorepo passava [title] até
  /// agora, mas aditivo continua sendo o caminho mais barato.
  final Widget? titleWidget;

  /// `true` remove a `AppBar` por completo, nos 2 modos (2026-08-14,
  /// achado real do usuário: `AppBar` + barra de navegação são 2
  /// faixas fixas empilhadas comendo altura - com [navLeading]
  /// preenchendo o mesmo papel DENTRO da própria navegação, a `AppBar`
  /// fica redundante). Default `false` preserva 100% o comportamento
  /// atual pra quem não passa este param.
  final bool hideAppBar;

  /// Conteúdo extra ANTES dos itens de navegação - em paisagem vira o
  /// `leading:` nativo do `NavigationRail` (topo do rail, acima dos
  /// ícones); em retrato vira a 1ª coluna fixa do
  /// [ScrollableBottomNavBar] (antes dos itens). Pensado pra
  /// acompanhar [hideAppBar]`: true` (substitui o que antes ficava em
  /// [titleWidget]), mas funciona independente disso também.
  final Widget? navLeading;

  /// Índice destacado (pill/indicador selecionado) no Rail/barra de
  /// baixo - `null` (default) usa [currentIndex], preservando 100% o
  /// comportamento antigo. Separado de [currentIndex] pra cobrir o
  /// caso de um consumidor que sobrepõe o CONTEÚDO de todo item por
  /// outra tela (overlay, sem gastar índice/ícone próprio na nav) sem
  /// que nenhum item pareça "selecionado" por engano - passar `-1`
  /// (fora do range de [items]) evita match com qualquer destino.
  final int? highlightIndex;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    this.floatingActionButton,
    this.title,
    this.actions,
    this.titleWidget,
    this.hideAppBar = false,
    this.navLeading,
    this.highlightIndex,
  });

  /// Compartilhado entre paisagem/retrato (antes duplicado, 1 `AppBar`
  /// por método) - [titleWidget] vence sobre [title] quando os dois
  /// existem.
  AppBar? _buildAppBar() {
    if (hideAppBar) return null;
    if (titleWidget == null && title == null && actions == null) return null;
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
    );
  }

  static const _duracaoTransicaoChrome = Duration(milliseconds: 300);

  /// Achado real do usuário (2026-08-17): "troco a orientação -> clico
  /// em voltar, da erro sem log" - stack real capturado: "There are
  /// multiple heroes that share the same tag" (ex. FAB de `PaScreen`).
  /// Causa raiz: a versão antiga envolvia o `Scaffold` INTEIRO (rail/
  /// bottom nav E o conteúdo do item ativo) num `AnimatedSwitcher` -
  /// durante o crossfade de 500ms as 2 árvores (saindo E entrando)
  /// ficavam montadas AO MESMO TEMPO, cada 1 com sua PRÓPRIA cópia de
  /// `items[currentIndex].screen` - qualquer `Hero`/`FloatingAction
  /// Button` de tag fixa dentro do item ativo duplicava, travando o
  /// controller de Hero do `Navigator` (o "voltar" parava de responder
  /// depois, sem crash de build visível - erro de scheduler).
  ///
  /// Mesmo bug que `ShellNavigationScaffold` (classe irmã, MESMO
  /// arquivo) já documentava e evitava desde 2026-08-07 (ver comentário
  /// dela) - nunca foi aplicado de volta aqui. Fix: reusa o MESMO
  /// padrão - o CONTEÚDO (`_buildAnimatedContent()`) fica montado 1 VEZ
  /// SÓ, dentro de 1 `Scaffold` único; só o "chrome" ao redor (Rail à
  /// esquerda vs `ScrollableBottomNavBar` embaixo) anima tamanho/
  /// opacidade via `AnimatedSize`/`AnimatedOpacity` - sem duplicar o
  /// item ativo em nenhum momento da transição.
  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final resolvedHighlight = highlightIndex ?? currentIndex;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: _duracaoTransicaoChrome,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: _duracaoTransicaoChrome,
              opacity: isLandscape ? 1 : 0,
              child: isLandscape
                  ? _buildNavigationRail(context, resolvedHighlight)
                  : const SizedBox.shrink(),
            ),
          ),
          AnimatedSize(
            duration: _duracaoTransicaoChrome,
            curve: Curves.easeInOut,
            child: isLandscape
                ? const VerticalDivider(thickness: 1, width: 1)
                : const SizedBox.shrink(),
          ),
          Expanded(child: _buildAnimatedContent()),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: _duracaoTransicaoChrome,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: isLandscape
            ? const SizedBox.shrink()
            : ScrollableBottomNavBar(
                items: items,
                currentIndex: resolvedHighlight,
                onIndexChanged: onIndexChanged,
                leading: navLeading,
              ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildNavigationRail(BuildContext context, int highlight) {
    // Mesmo achado/fix de `ShellNavigationScaffold` (2026-08-07) -
    // `NavigationRail` não rola sozinho quando os itens não cabem na
    // altura disponível. `LayoutBuilder` + `ConstrainedBox(minHeight)`
    // restaura o comportamento original (Rail esticado do topo ao
    // fim, achado real do usuário logo após o 1º fix - `IntrinsicHeight`
    // sozinho tirava o "esticar" e deixava o Rail centralizado/curto)
    // e ainda rola quando o conteúdo realmente não cabe.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              // `NavigationRail` exige `null` (não qualquer inteiro
              // fora do range) pra "nenhum destino selecionado" -
              // valores como -1 (usado por quem quer suprimir o
              // highlight, ver doc de [AdaptiveNavigationScaffold.
              // highlightIndex]) disparam assert de bounds.
              selectedIndex: (highlight >= 0 && highlight < items.length)
                  ? highlight
                  : null,
              onDestinationSelected: onIndexChanged,
              leading: navLeading,
              labelType: NavigationRailLabelType.all,
              // Ativa o visual Material 3 no Rail
              useIndicator: true,
              indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
              destinations: items
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Tooltip(
                        message: item.label,
                        child: Icon(item.icon),
                      ),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
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
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: currentIndex,
                              onDestinationSelected: onIndexChanged,
                              labelType: NavigationRailLabelType.all,
                              useIndicator: true,
                              indicatorColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              destinations: items
                                  .map(
                                    (item) => NavigationRailDestination(
                                      icon: Icon(item.icon),
                                      label: Text(item.label),
                                    ),
                                  )
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
    this.leading,
  });

  final List<AdaptiveNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  /// Conteúdo extra fixo ANTES dos itens (2026-08-14) - mesma altura
  /// da barra (`_alturaBarra`), largura tipo [_larguraItem]. `null`
  /// (default) não muda nada do layout existente.
  final Widget? leading;

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
              // Largura do `leading` reservada ANTES de dividir entre os
              // itens (2026-08-14) - senão ele "roubaria" espaço que os
              // cálculos abaixo assumem ser só dos itens.
              final larguraLeading = widget.leading != null
                  ? ScrollableBottomNavBar._larguraItem
                  : 0.0;
              final larguraDisponivel = (constraints.maxWidth - larguraLeading)
                  .clamp(0.0, double.infinity);
              final larguraPorItem = n == 0
                  ? larguraDisponivel
                  : larguraDisponivel / n;

              // Cabe tudo com texto - estica preenchendo a tela (achado
              // real, 2026-07-27: pedido do usuário pra não ficar sempre
              // no modo compacto/rolável quando sobra espaço de verdade).
              if (larguraPorItem >= ScrollableBottomNavBar._larguraItem) {
                return Row(
                  children: [
                    if (widget.leading != null) _buildLeading(),
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
                    if (widget.leading != null) _buildLeading(),
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
              // `leading` fica FORA do `SingleChildScrollView` (fixo, não
              // rola junto com os itens) - `Expanded` só na parte rolável.
              return Row(
                children: [
                  if (widget.leading != null) _buildLeading(),
                  Expanded(
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is! PointerScrollEvent) return;
                        if (!_scrollController.hasClients) return;
                        final alvo =
                            (_scrollController.offset + event.scrollDelta.dy)
                                .clamp(
                                  0.0,
                                  _scrollController.position.maxScrollExtent,
                                );
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() => SizedBox(
    width: ScrollableBottomNavBar._larguraItem,
    height: ScrollableBottomNavBar._alturaBarra,
    child: widget.leading,
  );

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
