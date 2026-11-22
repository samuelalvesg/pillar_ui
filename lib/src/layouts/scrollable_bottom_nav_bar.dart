import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../themes/app_motion.dart';
import '../widgets/focus_ring.dart';
import 'navigation_item.dart';

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
    final corConteudo = navItemColor(theme.colorScheme, selecionado);

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
              child: navItemIcon(item, cor: cor),
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
