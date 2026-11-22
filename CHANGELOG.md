## 0.1.0-alpha.2

Revisão de UI/UX e acessibilidade (`docs/ui-ux-review.md`).

**Mudanças que alteram o comportamento visível**

* Rail ou barra inferior passa a ser decidido pela **largura** (`railBreakpoint`, padrão 600 dp), não pela orientação. Um tablet em retrato agora usa o rail; uma janela estreita e baixa usa a barra.
* `AppTheme.light` e `AppTheme.dark` usam o mesmo caminho (`ColorScheme.fromSeed` com `brightness`); o claro deixa de trocar `surface` por `Colors.grey[50]`.
* `AppTextTheme`: sem `color` fixo (o `displayLarge` preto quebrava o modo escuro), títulos em Poppins e corpo em Inter (o `displayMedium` deixa de ser Roboto).
* `ErrorContainerWidget`: texto e ícone em `onErrorContainer`, estilo `bodySmall` do tema, região viva para leitor de tela.
* `CollapsibleEdgeDrawer`: aba de 48 dp (era 40) e ícone de 20.
* A barra inferior cresce com a escala de fonte do usuário.
* O destino ativo deixa de ter a pílula: a seleção é só cor, ícone e rótulo em `onSurface` (branco no escuro, preto no claro) e os inativos num cinza (`onSurface` a 68% sobre a superfície, contraste ≥ 4,5:1). O rail também (`useIndicator: false`). O estado continua no leitor de tela (`selected`).

**Novo (aditivo)**

* `extendedRailBreakpoint` nos dois scaffolds: rail com ícone e rótulo lado a lado a partir dessa largura (padrão `null`: rail estreito).
* Teclado: `Tab` percorre a barra e o rail, setas movem o foco, `Enter`/`Espaço` ativam, anel de foco visível só por teclado, `Alt+1` a `Alt+9` selecionam os 9 primeiros destinos (`enableKeyboardShortcuts`, padrão `true`).
* Semântica: item da barra inferior anuncia nome, botão e selecionado; aba do drawer anuncia nome (`toggleTooltip`), botão e expandido.
* `ErrorContainerWidget`: `onRetry` + `retryLabel` opcionais.
* Movimento reduzido: `AppMotion.duration` zera as animações quando o sistema pede; `AnimatedSizeOrCut` evita a asserção do `AnimatedSize` com duração zero.
* Tokens: `AppSpacing`, `AppMotion`, `StatusColors` (sucesso e aviso com par `on*`, contraste ≥ 4,5:1).

**Descontinuado:** `AppColors.primaryLight`, `success`, `warning`, `danger`.

## 0.1.0-alpha.1

* Migra de `flutter/material` para `material_ui` (Flutter 3.50). Quem usa o pacote precisa do Flutter 3.50 e passa a receber o `ThemeData` do `material_ui`.
* `AdaptiveNavigationItem` ganha `badgeCount` (`int`, padrão `0`) - contador
  (`Badge.count`) sobre o ícone no rail e na barra inferior.
* `AdaptiveNavigationScaffold` ganha `titleWidget` (`Widget?`) - título
  rico, vence sobre `title` (`String?`) quando os dois são passados.

## 0.0.1

* TODO: Describe initial release.
