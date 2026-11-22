import 'package:material_ui/material_ui.dart';

import '../themes/app_motion.dart';
import 'navigation_breakpoints.dart';
import 'navigation_chrome.dart';
import 'navigation_item.dart';
import 'navigation_shortcuts.dart';
import 'scrollable_bottom_nav_bar.dart';

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

  /// Altura da barra inferior (`ScrollableBottomNavBar`) - `null` (default)
  /// usa o padrão do widget. Repassado sem alterar comportamento de quem
  /// não passa nada (pedido do usuário, 2026-09-03: reduzir o espaço em
  /// branco acima do ícone/abaixo do texto na barra, mas configurável em
  /// vez de fixo, já que outros consumidores do pacote podem preferir o
  /// tamanho original).
  final double? navBarHeight;

  /// Padding vertical ao redor do ícone da barra inferior (o "espaço em
  /// branco acima do botão") - `null` usa o padrão do widget.
  final double? navBarIconPadding;

  /// Espaço entre ícone e label na barra inferior (o "espaço abaixo do
  /// texto" fica implícito nisso + na altura total, já que o conteúdo é
  /// centralizado verticalmente) - `null` usa o padrão do widget.
  final double? navBarLabelGap;

  /// Largura máxima do label de cada destino do `NavigationRail`
  /// (barra vertical, paisagem) - força o texto a quebrar em até 2 linhas
  /// em vez de alargar o Rail inteiro pra caber numa linha só. `null`
  /// (default) preserva o comportamento original (1 linha, Rail alarga
  /// conforme o label mais longo).
  final double? navRailLabelMaxWidth;

  /// Tamanho da fonte do label dos destinos (barra inferior e Rail) - `null`
  /// preserva o padrão (11 na barra inferior, estilo do tema no Rail).
  final double? navLabelFontSize;

  /// Largura mínima do `NavigationRail` - `null` usa o padrão do Material
  /// (72).
  final double? navRailMinWidth;

  /// Window width (dp) from which the rail replaces the bottom bar.
  final double railBreakpoint;

  /// Window width (dp) from which the rail shows icon and label side by
  /// side. `null` (default) keeps the narrow rail at every width.
  final double? extendedRailBreakpoint;

  /// Ctrl+Tab / Ctrl+Shift+Tab cycle the destinations and
  /// [shortcutModifier]+1..9 jump to one of the first nine.
  final bool enableKeyboardShortcuts;

  /// Modifier of the jump-to-destination shortcuts.
  final NavigationShortcutModifier shortcutModifier;

  /// `false` collapses the bottom bar (for example while reading, in sync
  /// with a header that hides). Ignored when the rail is showing.
  final bool bottomBarVisible;

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
    this.navBarHeight,
    this.navBarIconPadding,
    this.navBarLabelGap,
    this.navRailLabelMaxWidth,
    this.navLabelFontSize,
    this.navRailMinWidth,
    this.railBreakpoint = kDefaultRailBreakpoint,
    this.extendedRailBreakpoint,
    this.enableKeyboardShortcuts = true,
    this.shortcutModifier = NavigationShortcutModifier.alt,
    this.bottomBarVisible = true,
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
    final showRail = showNavRail(context, railBreakpoint);
    final highlight = highlightIndex ?? currentIndex;
    final dur = AppMotion.duration(context, AppMotion.long);

    return NavShortcuts(
      enabled: enableKeyboardShortcuts,
      modifier: shortcutModifier,
      currentIndex: currentIndex,
      itemCount: items.length,
      onIndexChanged: onIndexChanged,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: NavBody(
          showRail: showRail,
          duration: dur,
          rail: NavRail(
            items: items,
            selectedIndex: highlight,
            onSelected: onIndexChanged,
            extendedBreakpoint: extendedRailBreakpoint,
            leading: navLeading,
            minWidth: navRailMinWidth,
            labelMaxWidth: navRailLabelMaxWidth,
            labelFontSize: navLabelFontSize,
          ),
          content: _buildAnimatedContent(context),
        ),
        bottomNavigationBar: BottomBarSlot(
          showRail: showRail,
          visible: bottomBarVisible,
          duration: dur,
          bar: ScrollableBottomNavBar(
            items: items,
            currentIndex: highlight,
            onIndexChanged: onIndexChanged,
            leading: navLeading,
            barHeight: navBarHeight,
            iconPadding: navBarIconPadding,
            labelGap: navBarLabelGap,
            labelFontSize: navLabelFontSize,
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.long),
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
