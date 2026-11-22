# Revisão de UI/UX do pillar_ui

Data: 2026-11-22. Escopo: `lib/` do pillar_ui na branch `claude/project-thread-8b5gsi` (1.165 linhas: tema, `AdaptiveNavigationScaffold`, `ShellNavigationScaffold`, `ScrollableBottomNavBar`, `CollapsibleEdgeDrawer`, `ErrorContainerWidget`, `DeferredWidget`).
Método: leitura do código e busca por padrões (`grep`) contra as referências abaixo. **Não executei o app nem medi contraste em tela**; os achados de contraste são por leitura de código. Nada foi alterado no código do pacote.

## Referências usadas

| Pilar | Referência | O que ela exige |
|---|---|---|
| Navegação adaptativa | [Material 3 window size classes / Build adaptive navigation](https://developer.android.com/develop/adaptive-apps/guides/build-adaptive-navigation) | Compacto: barra inferior (ou drawer modal); médio: rail; expandido: rail ou drawer permanente. Rail só com 3 ou mais destinos. |
| Responsivo no Flutter | [General approach to adaptive apps](https://docs.flutter.dev/ui/adaptive-responsive/general), [Best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices) | Medir o espaço do widget (`LayoutBuilder`), ramificar por breakpoint Material (600 dp), não perguntar "é celular ou tablet", não esticar conteúdo em tela larga. |
| Acessibilidade | [WCAG 2.2, 2.5.8 Target Size (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum), [Baseflow: touch targets](https://baseflow.github.io/accessibility-guidelines/navigation/touch-targets.html) | Alvo ≥ 24×24 (AA); 48 dp é a recomendação Material. `GestureDetector` customizado é onde as violações aparecem. |
| Erros e estados | [NN/g: error message guidelines](https://www.nngroup.com/articles/error-message-guidelines/), [10 heurísticas](https://www.nngroup.com/articles/ten-usability-heuristics/) | Erro perto da origem, nunca só por cor, dizer o que houve e como resolver, sem culpar o usuário. |
| Tokens | Skill `flutter-design-system` do claude-agents | Tudo via `Theme.of(context)`; escala 4/8 pt; `ThemeExtension` para token de marca. |

Limite da pesquisa: as páginas oficiais m3.material.io não apareceram na busca; usei a documentação do Android e do Flutter, que repetem o guia. Uma fonte (SAP) diz que o drawer está sendo substituído pelo rail expandido no Material 3 Expressive; não confirmei na fonte oficial.

## Achados (por prioridade)

### Alta
1. **Aba do `CollapsibleEdgeDrawer` sem nome acessível e abaixo do alvo recomendado.** `_CollapseTab` usa `GestureDetector` (sem `Semantics`, sem foco de teclado, sem hover) e tem 40 dp de largura com ícone de 16. Leitor de tela não anuncia o botão nem o estado aberto/fechado. Correção: `InkWell`/`IconButton` com `tooltip` e `Semantics(button: true, expanded: isOpen)`; alvo ≥ 48 dp (a largura visual pode ficar fina com área de toque maior). Texto do tooltip vem de parâmetro, para não fixar idioma.
2. **Tema escuro e claro não são simétricos, e há cor fixa que quebra o escuro.** `AppTextTheme.displayLarge` tem `color: Colors.black` (o comentário diz que o Flutter ajusta; não ajusta, texto preto sobre superfície escura). `AppTheme.light` troca `surface` por `Colors.grey[50]`, o `dark` não tem equivalente e usa `colorSchemeSeed` enquanto o claro usa `ColorScheme.fromSeed`. Correção: remover `color` dos estilos, um único caminho `ColorScheme.fromSeed(brightness:)` para os dois, e testar contraste 4,5:1 nos pares texto/superfície.
3. **`ErrorContainerWidget` não segue os pares de cor do Material nem é anunciado.** Texto em `colorScheme.error` sobre `errorContainer` (o par correto é `onErrorContainer`; `error` sobre `errorContainer` costuma ficar abaixo de 4,5:1). `fontSize: 13` fixo ignora o `textTheme` e a escala de fonte. Sem `Semantics(liveRegion: true)`, então erro que aparece depois não é falado. Só mensagem, sem ação de recuperação (heurística 9 da NN/g). Correção: `onErrorContainer`, `textTheme.bodySmall`, `liveRegion`, parâmetro opcional `onRetry`/ação.

### Média
4. **Breakpoint por orientação, não por largura.** Os dois scaffolds usam `size.width > size.height` para escolher rail ou barra inferior. Um celular em paisagem ganha rail, um tablet em retrato ganha barra inferior, e uma janela larga e baixa no desktop se comporta como celular. O guia Material/Flutter manda usar a largura (compacto < 600, médio 600–839, expandido ≥ 840) medida por `LayoutBuilder`. Mudança de comportamento: tratar como alteração visível no CHANGELOG, com parâmetro para manter o modo antigo se algum app depender.
5. **Rail com menos de 3 destinos e sem modo expandido.** O Material pede rail só com 3 ou mais destinos e oferece rail expandido (ícone + rótulo) para larguras grandes. O pacote só tem rail estreito.
6. **Movimento sem respeitar "reduzir movimento".** Há durações de 200 a 300 ms (`AnimatedSize`, transição entre rail e barra, `AnimatedContainer` do item) e nenhum uso de `MediaQuery.disableAnimationsOf`. Correção: um helper que devolve `Duration.zero` quando a preferência está ligada.
7. **Escala de fonte não testada.** Não há `textScaler` nem teste a 200%; `ScrollableBottomNavBar` tem `barHeight` e `labelFontSize` fixos, então rótulo grande trunca ou estoura. Correção: altura mínima com `textScaler` ou rótulo com `FittedBox`/duas linhas, e um teste de widget com `textScaler: TextScaler.linear(2)`.
8. **Item da barra inferior sem semântica de seleção.** O item usa `InkWell` + `Tooltip`; sem `Semantics(selected: ...)` o leitor de tela não diz qual aba está ativa (o `NavigationBar` do Material faz isso, a barra própria perdeu).

### Baixa
9. **Tipografia incoerente.** `displayMedium` em Roboto, `displayLarge` em Poppins, `bodyMedium` em Inter, e só 3 dos 15 estilos do Material 3 definidos. Escolher uma família de títulos e uma de corpo e derivar a escala completa de `ThemeData.textTheme.apply`. `google_fonts` baixa a fonte em tempo de execução (rede, offline, privacidade): para apps offline, empacotar a fonte.
10. **Tokens de cor ociosos.** `AppColors.success/warning/danger`, `secondary`, `tertiary` não entram no `ColorScheme` (o `fromSeed` gera os próprios), e `primary == primaryLight`. Dar um `ThemeExtension<StatusColors>` para sucesso/aviso/perigo com pares `on*` em vez de constantes soltas; remover `primaryLight`.
11. **Sem escala de espaçamento.** Valores soltos (12, 16, `iconPadding`). Criar `AppSpacing` (4/8/12/16/24/32) e usar nos widgets.
12. **Strings e comentários.** Comentários de histórico em português ("achado real, 2026-07-27", "pedido do usuário") contrariam a regra do projeto (comentar só o porquê, em inglês no código novo); não traduzir em massa, só ao tocar o arquivo. Cabeçalhos de arquivo vazios (`Premissas: ✅`) são ruído.
13. **Cobertura de teste de UI.** Há testes de navegação e de rótulo, nenhum de tema (contraste dos pares), do drawer, do `ErrorContainerWidget` nem de semântica. Cada correção acima deve trazer o teste correspondente.

## Ordem sugerida
Um PR só, em fatias: (1) tema simétrico e sem cor fixa (achado 2, 9, 10); (2) semântica e alvos (1, 3, 8); (3) breakpoint por largura e movimento reduzido (4, 5, 6, 7). Os itens 4 e 5 mudam comportamento visível: precisam do aval do Samuel e de aviso aos apps consumidores.

## Como isso foi repassado
Ver a skill `ui-ux-pillars` e as mudanças em `developer.md` do perfil pillar-ui, descritas na resposta da thread.
