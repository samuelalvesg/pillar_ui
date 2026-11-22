# Conceitos de navegação com animação e Hero para o pillar_ui

Data: 2026-11-22. Pesquisa de referências; **nada foi prototipado nem rodado**, e não conferi a compatibilidade do pacote `animations` com `material_ui` (o pillar_ui importa `material_ui`, não `material`). Este é o ponto a validar antes de qualquer código.

## O que as referências dizem

- **Padrões de movimento do Material** ([motion system](https://material.io/design/motion/the-motion-system.html), [codelab Flutter](https://codelabs.developers.google.com/codelabs/material-motion-flutter)): *container transform* (card que vira a página de detalhe), *shared axis* (relação espacial: x para fluxo, y para stepper, z para pai→filho), *fade through* (destinos sem relação forte, como as abas da barra inferior) e *fade* (diálogos, menus). O guia diz que shared axis pode piscar e que, nesse caso, um fade simples é melhor, principalmente no eixo z.
- **Pacote oficial [`animations`](https://pub.dev/packages/animations)** (flutter.dev, 2.1.1, exige Flutter 3.32+): `OpenContainer`, `SharedAxisTransition`, `FadeThroughTransition`, com `PageTransitionSwitcher`.
- **[Hero](https://docs.flutter.dev/ui/animations/hero-animations)**: elemento compartilhado entre rotas; o voo roda em overlay e começa na navegação de/para a rota. Limite documentado: Hero não funciona dentro de `OpenContainer` nem de `PageTransitionSwitcher`. Ou seja, uma troca de aba que não é rota não dispara Hero.
- **Barras com visual diferente (pacotes de comunidade, manutenção não verificada)**: [motionx](https://pub.dev/packages/motionx) (indicador flutuante que segue o gesto), [bottom_navigation_bar_kit](https://pub.dev/documentation/bottom_navigation_bar_kit/latest/) (pílula deslizante, efeito "worm"), [bottom_navigator](https://pub.dev/documentation/bottom_navigator/latest/) (variante flutuante, vidro), [floatica](https://pub.dev/documentation/floatica/1.2.1/). Servem de inspiração visual; para um pacote compartilhado recomendo implementar o indicador próprio (já existe `ScrollableBottomNavBar`) em vez de depender deles.

## Três conceitos

**A. Conservador: troca de aba com *fade through*.** Mantém o visual atual; o corpo do scaffold passa a trocar com `FadeThroughTransition` e o indicador do item ganha deslize. Menor risco e menor esforço; é o padrão que o Material prescreve para destinos da barra inferior.

**B. Barra flutuante em pílula com indicador deslizante.** Em largura compacta, a barra vira uma cápsula flutuante (margem, elevação, cantos `StadiumBorder`) com um indicador que desliza entre os itens, e o item selecionado mostra o rótulo (os outros só ícone). Em largura média/expandida vira rail (estendido em ≥ 840). Reaproveita a rolagem horizontal do `ScrollableBottomNavBar` para muitas abas. Custo: alvo de toque e contraste do indicador precisam de teste; barra flutuante cobre o conteúdo, então o corpo precisa de padding inferior.

**C. Hero no fluxo lista → detalhe.** Dentro de cada aba, tocar num item empurra uma rota com `Hero` (ícone/avatar/título) ou *container transform*. A barra de navegação continua fixa. Não vale para a troca de aba em si (não é rota). Pendente de verificação: como o `HeroController` se comporta com `StatefulShellRoute` do go_router, que usa um navegador por ramo (não confirmei na documentação).

**Combinação que recomendo: B + C, com A como fallback.** B dá a identidade visual própria que você descreveu, C dá a continuidade entre telas, e o fade through cobre as trocas de aba sem relação.

## Regras de movimento (valem para qualquer conceito)

- Tokens de movimento num lugar só (`ThemeExtension<MotionTokens>`): durações curta/média/longa (hoje há 200, 250, 280 e 300 ms soltos) e curvas padrão/ênfase.
- Respeitar `MediaQuery.disableAnimationsOf`: movimento vira `Duration.zero` e o Hero vira corte seco.
- Animar só `transform` e `opacity` (barato); nada de relayout por frame em listas longas.
- Parâmetro `NavigationStyle` (clássico, flutuante) para os apps consumidores migrarem sem quebra; o padrão atual não muda até o aval do Samuel.
- Cada conceito traz teste de widget: semântica da aba selecionada, texto a 200%, movimento reduzido, largura estreita e larga.

## Próximos passos (precisam de decisão)
1. Escolher o conceito (recomendo B + C).
2. Verificar `animations` com `material_ui` e `HeroController` com go_router (spike de uma hora, não de produção).
3. Protótipo atrás de `NavigationStyle` no pillar_ui, em PR draft separado deste.
