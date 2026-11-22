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
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../themes/app_motion.dart';
import '../widgets/focus_ring.dart';

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

/// Estilo do rótulo dos destinos do `NavigationRail` (barra vertical).
///
/// Mesmo peso do rótulo da barra inferior ([ScrollableBottomNavBar]), que é um widget próprio e usa o
/// peso normal do tema. O `NavigationRail` do Material define o rótulo com `labelMedium` (peso 500) e
/// o `TextStyle(fontSize: ...)` passado pelo app só é MESCLADO com isso, então o rail ficava com
/// aparência de negrito enquanto a barra horizontal não (achado do usuário, 2026-09-25). Fixar o peso
/// aqui - numa função só, usada pelos dois scaffolds - mantém as duas barras iguais.
///
/// [fontSize] `null` mantém o tamanho padrão do Material.
TextStyle estiloRotuloDoRail(double? fontSize) =>
    TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400);

/// Material "medium" window class starts at 600 dp: from there navigation is
/// a rail, below it a bottom bar. Decided by width, never by orientation.
const double kDefaultRailBreakpoint = 600;

/// Modifier key of the "jump to destination N" shortcuts.
enum NavigationShortcutModifier {
  /// Alt+1 .. Alt+9. Works inside browsers, which keep Ctrl+digit for their
  /// own tabs.
  alt,

  /// Ctrl+1 .. Ctrl+9. The desktop-app convention.
  control,
}

/// Keyboard navigation of the shell: Ctrl+Tab / Ctrl+Shift+Tab cycle through
/// the destinations (wrapping), and `modifier`+1..9 jump straight to one.
/// Also gives the shell a reading-order focus group, so Tab walks the visible
/// screen top to bottom and then the navigation.
///
/// Focus held inside a screen that is being hidden would be lost; after a
/// shortcut the shell's own scope takes it, which keeps the shortcuts working
/// (key events only reach shortcuts above a focused node) and makes the next
/// Tab press start from the newly shown screen.
class _NavShortcuts extends StatefulWidget {
  const _NavShortcuts({
    required this.enabled,
    required this.modifier,
    required this.currentIndex,
    required this.itemCount,
    required this.onIndexChanged,
    required this.child,
  });

  final bool enabled;
  final NavigationShortcutModifier modifier;
  final int currentIndex;
  final int itemCount;
  final ValueChanged<int> onIndexChanged;
  final Widget child;

  @override
  State<_NavShortcuts> createState() => _NavShortcutsState();
}

class _NavShortcutsState extends State<_NavShortcuts> {
  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  final _scope = FocusScopeNode(debugLabel: 'NavShortcuts');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _select(int index) {
    _scope.requestFocus();
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.itemCount == 0) return widget.child;
    final count = widget.itemCount;
    final current = widget.currentIndex;
    final alt = widget.modifier == NavigationShortcutModifier.alt;
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.tab, control: true): () =>
            _select((current + 1) % count),
        SingleActivator(
          LogicalKeyboardKey.tab,
          control: true,
          shift: true,
        ): () =>
            _select((current - 1 + count) % count),
        for (var i = 0; i < count && i < _digits.length; i++)
          SingleActivator(_digits[i], alt: alt, control: !alt): () =>
              _select(i),
      },
      child: FocusScope(
        node: _scope,
        autofocus: true,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Active destinations use `onSurface` (white on dark, black on light);
/// inactive ones a grey: `onSurface` blended 68% over the bar surface, which
/// keeps at least 4.5:1 against it and stays visibly dimmer than the active one.
Color _corDoItem(ColorScheme scheme, bool selecionado) => selecionado
    ? scheme.onSurface
    : Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.68),
        scheme.surfaceContainer,
      );

bool _showRail(BuildContext context, double breakpoint) =>
    MediaQuery.sizeOf(context).width >= breakpoint;

bool _extendedRail(BuildContext context, double? breakpoint) =>
    breakpoint != null && MediaQuery.sizeOf(context).width >= breakpoint;

class AdaptiveNavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  /// Contador sobre o ícone (ex.: notificações não lidas). `0` = sem badge.
  /// Aditivo (2026-09-30): nenhum consumidor existente precisa mudar.
  final int badgeCount;

  const AdaptiveNavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.badgeCount = 0,
  });
}

/// Ícone do item com o badge de [AdaptiveNavigationItem.badgeCount] quando
/// > 0 - o MESMO nas 3 formas da barra (rail do layout largo, rail da
/// paisagem e barra inferior), para o contador não sumir ao girar a tela.
Widget _iconeDoItem(AdaptiveNavigationItem item, {Color? cor}) {
  final icone = Icon(item.icon, color: cor);
  if (item.badgeCount <= 0) return icone;
  return Badge.count(count: item.badgeCount, child: icone);
}

/// The rail both scaffolds share: scrolls when the destinations do not fit,
/// stretches to the full height when they do, and colors the active
/// destination by icon and label only (no indicator pill).
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.extendedBreakpoint,
    this.leading,
    this.minWidth,
    this.labelMaxWidth,
    this.labelFontSize,
  });

  final List<AdaptiveNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? extendedBreakpoint;
  final Widget? leading;
  final double? minWidth;
  final double? labelMaxWidth;
  final double? labelFontSize;

  /// Without [labelMaxWidth] the label stays on one line and the rail widens
  /// to the longest one; with it the label wraps to two lines instead.
  Widget _label(String label) {
    final style = estiloRotuloDoRail(labelFontSize);
    final maxWidth = labelMaxWidth;
    if (maxWidth == null) return Text(label, style: style);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        label,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extended = _extendedRail(context, extendedBreakpoint);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              // `NavigationRail` asserts on an out-of-range index; `null` is
              // how "no destination selected" is expressed (see
              // [AdaptiveNavigationScaffold.highlightIndex]).
              selectedIndex:
                  (selectedIndex >= 0 && selectedIndex < items.length)
                  ? selectedIndex
                  : null,
              onDestinationSelected: onSelected,
              leading: leading,
              minWidth: minWidth,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              useIndicator: false,
              selectedIconTheme: IconThemeData(color: _corDoItem(scheme, true)),
              unselectedIconTheme: IconThemeData(
                color: _corDoItem(scheme, false),
              ),
              selectedLabelTextStyle: TextStyle(
                color: _corDoItem(scheme, true),
              ),
              unselectedLabelTextStyle: TextStyle(
                color: _corDoItem(scheme, false),
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: item.label,
                      child: _iconeDoItem(item),
                    ),
                    label: _label(item.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail + divider + content. The rail and divider animate in and out as
/// [showRail] flips; [content] stays mounted exactly once (a duplicated
/// subtree would duplicate `Hero` tags and the router's navigator).
class _NavBody extends StatelessWidget {
  const _NavBody({
    required this.showRail,
    required this.duration,
    required this.rail,
    required this.content,
  });

  final bool showRail;
  final Duration duration;
  final Widget rail;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSizeOrCut(
          duration: duration,
          curve: AppMotion.standard,
          child: AnimatedOpacity(
            duration: duration,
            opacity: showRail ? 1 : 0,
            child: showRail ? rail : const SizedBox.shrink(),
          ),
        ),
        AnimatedSizeOrCut(
          duration: duration,
          curve: AppMotion.standard,
          child: showRail
              ? const VerticalDivider(thickness: 1, width: 1)
              : const SizedBox.shrink(),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Slot of the bottom bar: it collapses when the rail takes over.
class _BottomBarSlot extends StatelessWidget {
  const _BottomBarSlot({
    required this.showRail,
    required this.visible,
    required this.duration,
    required this.bar,
  });

  final bool showRail;
  final bool visible;
  final Duration duration;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    return AnimatedSizeOrCut(
      duration: duration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: showRail || !visible ? const SizedBox.shrink() : bar,
    );
  }
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
    final showRail = _showRail(context, railBreakpoint);
    final highlight = highlightIndex ?? currentIndex;
    final dur = AppMotion.duration(context, AppMotion.long);

    return _NavShortcuts(
      enabled: enableKeyboardShortcuts,
      modifier: shortcutModifier,
      currentIndex: currentIndex,
      itemCount: items.length,
      onIndexChanged: onIndexChanged,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _NavBody(
          showRail: showRail,
          duration: dur,
          rail: _NavRail(
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
        bottomNavigationBar: _BottomBarSlot(
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

/// Shell de Navegação diretamente integrada ao GoRouter StatefulShellRoute.
/// Usa [navigationShell] como corpo gerenciado pelo roteador.
class ShellNavigationScaffold extends StatelessWidget {
  final Widget navigationShell;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<AdaptiveNavigationItem> items;

  /// Mesmo significado de `AdaptiveNavigationScaffold.navBarHeight`/
  /// `navBarIconPadding`/`navBarLabelGap`/`navRailLabelMaxWidth` - `null`
  /// preserva o comportamento original.
  final double? navBarHeight;
  final double? navBarIconPadding;
  final double? navBarLabelGap;
  final double? navRailLabelMaxWidth;
  final double? navLabelFontSize;
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

  const ShellNavigationScaffold({
    super.key,
    required this.navigationShell,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
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

  @override
  Widget build(BuildContext context) {
    final showRail = _showRail(context, railBreakpoint);
    final dur = AppMotion.duration(context, AppMotion.medium);

    // `navigationShell` (the router's navigator) is mounted once, always:
    // only the chrome around it animates. See [_NavBody].
    return _NavShortcuts(
      enabled: enableKeyboardShortcuts,
      modifier: shortcutModifier,
      currentIndex: currentIndex,
      itemCount: items.length,
      onIndexChanged: onIndexChanged,
      child: Scaffold(
        body: _NavBody(
          showRail: showRail,
          duration: dur,
          rail: _NavRail(
            items: items,
            selectedIndex: currentIndex,
            onSelected: onIndexChanged,
            extendedBreakpoint: extendedRailBreakpoint,
            minWidth: navRailMinWidth,
            labelMaxWidth: navRailLabelMaxWidth,
            labelFontSize: navLabelFontSize,
          ),
          content: navigationShell,
        ),
        bottomNavigationBar: _BottomBarSlot(
          showRail: showRail,
          visible: bottomBarVisible,
          duration: dur,
          bar: ScrollableBottomNavBar(
            items: items,
            currentIndex: currentIndex,
            onIndexChanged: onIndexChanged,
            barHeight: navBarHeight,
            iconPadding: navBarIconPadding,
            labelGap: navBarLabelGap,
            labelFontSize: navLabelFontSize,
          ),
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
    double? barHeight,
    double? iconPadding,
    double? labelGap,
    double? labelFontSize,
  }) : barHeight = barHeight ?? _alturaBarraDefault,
       iconPadding = iconPadding ?? _iconPaddingDefault,
       labelGap = labelGap ?? _labelGapDefault,
       labelFontSize = labelFontSize ?? _labelFontSizeDefault;

  final List<AdaptiveNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  /// Conteúdo extra fixo ANTES dos itens (2026-08-14) - mesma altura
  /// da barra ([barHeight]), largura tipo [_larguraItem]. `null`
  /// (default) não muda nada do layout existente.
  final Widget? leading;

  /// Altura total da barra - default [_alturaBarraDefault]. Reduzir
  /// diminui proporcionalmente o espaço em branco acima do ícone/abaixo
  /// do label (o conteúdo é centralizado verticalmente dentro da altura
  /// total).
  final double barHeight;

  /// Padding vertical do "pill" ao redor do ícone - default
  /// [_iconPaddingDefault]. Reduzir aproxima o ícone das bordas
  /// superior/inferior do item.
  final double iconPadding;

  /// Espaço entre ícone e label - default [_labelGapDefault].
  final double labelGap;

  /// Tamanho da fonte do label - default [_labelFontSizeDefault].
  final double labelFontSize;

  static const double _labelFontSizeDefault = 11;
  static const double _alturaBarraDefault = 64;
  static const double _iconPaddingDefault = 4;
  static const double _labelGapDefault = 4;
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
      duration: AppMotion.duration(context, AppMotion.short),
      curve: AppMotion.emphasized,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  late double _altura = widget.barHeight;

  /// Grows the bar with the user's text scale so the label never clips
  /// (the extra is the label's own growth).
  double _alturaEfetiva(BuildContext context) {
    final base = widget.labelFontSize;
    return widget.barHeight +
        (MediaQuery.textScalerOf(context).scale(base) - base);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _altura = _alturaEfetiva(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _altura,
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
    height: _altura,
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
    final corConteudo = _corDoItem(theme.colorScheme, selecionado);

    // Sem `width` fixo aqui - quem chama decide: `Expanded` (modo
    // esticado, cabe tudo) preenche o espaço disponível sozinho; modo
    // rolável (abaixo) envolve com `SizedBox(width: _larguraItem)`.
    //
    // A seleção é só de cor (ícone e rótulo), sem fundo: ativo em
    // `onSurface`, inativo em `onSurfaceVariant`. O estado também vai para o
    // leitor de tela (`Semantics.selected`), pois cor sozinha não basta.
    final conteudo = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: corConteudo),
      duration: AppMotion.duration(context, AppMotion.short),
      builder: (context, cor, _) => SizedBox(
        height: _altura,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.iconPadding,
              ),
              child: _iconeDoItem(item, cor: cor),
            ),
            if (mostrarTexto) ...[
              SizedBox(height: widget.labelGap),
              Text(
                item.label,
                style: TextStyle(fontSize: widget.labelFontSize, color: cor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );

    // Tooltip (hover no desktop/web, long-press no touch) - mais importante
    // ainda quando `mostrarTexto: false` (modo compacto ícone-só), mas
    // ajuda em qualquer modo.
    return Semantics(
      button: true,
      selected: selecionado,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: FocusRing(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            child: Semantics(
              label: mostrarTexto ? null : item.label,
              child: conteudo,
            ),
          ),
        ),
      ),
    );
  }
}
