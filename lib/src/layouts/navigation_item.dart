import 'package:material_ui/material_ui.dart';

/// Estilo do rótulo dos destinos do `NavigationRail` (barra vertical).
///
/// Mesmo peso do rótulo da barra inferior ([ScrollableBottomNavBar]), que é um widget próprio e usa o
/// peso normal do tema. O `NavigationRail` do Material define o rótulo com `labelMedium` (peso 500) e
/// o `TextStyle(fontSize: ...)` passado pelo app só é MESCLADO com isso, então o rail ficava com
/// aparência de negrito enquanto a barra horizontal não (achado do usuário, 2026-09-25). Fixar o peso
/// aqui - numa função só, usada pelos dois scaffolds - mantém as duas barras iguais.
///
/// [fontSize] `null` usa [kNavLabelFontSizeDefault], o mesmo da barra inferior
/// (o padrão do Material, 12, deixava o rail com rótulo maior).
TextStyle estiloRotuloDoRail(double? fontSize) => TextStyle(
  fontSize: fontSize ?? kNavLabelFontSizeDefault,
  fontWeight: FontWeight.w400,
);

/// Label size shared by the bottom bar and the rail.
const double kNavLabelFontSizeDefault = 11;

/// Active destinations use `onSurface` (white on dark, black on light);
/// inactive ones a grey: `onSurface` blended 68% over the bar surface, which
/// keeps at least 4.5:1 against it and stays visibly dimmer than the active one.
Color navItemColor(ColorScheme scheme, bool selecionado) => selecionado
    ? scheme.onSurface
    : Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.68),
        scheme.surfaceContainer,
      );

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
Widget navItemIcon(AdaptiveNavigationItem item, {Color? cor}) {
  final icone = Icon(item.icon, color: cor);
  if (item.badgeCount <= 0) return icone;
  return Badge.count(count: item.badgeCount, child: icone);
}
