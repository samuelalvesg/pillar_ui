# pillar_ui

Componentes de UI Flutter compartilhados entre os apps do ecossistema
`pillar_*` (Symmetris e outros projetos, ex. `sound_mixer_ui_app`) -
navegação responsiva, tema padrão e widgets utilitários reusados em
mais de um app.

## Conteúdo

### Layouts (`lib/src/layouts/`)

- **`AdaptiveNavigationScaffold`** - shell de navegação responsivo:
  `NavigationRail` lateral em paisagem, `ScrollableBottomNavBar`
  rolável embaixo em retrato, com transição animada entre os dois.
  Aceita `titleWidget` (`Widget?`, vence sobre `title` string) pra
  plugar uma barra de status rica e persistente acima de todas as
  abas.
- **`ShellNavigationScaffold`** - mesmo padrão visual, mas integrado
  diretamente ao `StatefulShellRoute` do GoRouter (`navigationShell`
  como corpo gerenciado pelo roteador em vez de lista de telas).
- **`ScrollableBottomNavBar`** - barra de navegação inferior rolável
  horizontalmente (substitui o `NavigationBar` padrão do Material, que
  divide a largura igualmente entre todos os itens e fica ilegível
  com muitas abas).

### Temas (`lib/src/themes/`)

- `app_colors.dart`/`app_text_theme.dart`/`app_theme.dart` - paleta e
  tipografia padrão compartilhadas.

### Widgets (`lib/src/widgets/`)

- **`ErrorContainerWidget`** - card de erro padronizado.
- **`DeferredWidget`** - wrapper pra carregamento tardio de telas
  pesadas (`deferred as`), reduz o bundle inicial.

## Acessibilidade e teclado

- O destino ativo é indicado só pela cor (ativo `onSurface`, inativo cinza), sem pílula; o leitor de tela recebe `selected`.
- `Tab` percorre a barra inferior ou o rail, as setas movem o foco entre os destinos, `Enter` e `Espaço` ativam; o anel de foco aparece só na navegação por teclado.
- `Alt+1` a `Alt+9` selecionam os nove primeiros destinos (`enableKeyboardShortcuts: false` desliga). `Alt`, e não `Ctrl`, porque os navegadores reservam `Ctrl+número`.
- Textos de tooltip e de ação (`toggleTooltip` do drawer, `retryLabel` do erro) vêm do app: o pacote não fixa idioma.
- Com "reduzir movimento" ligado no sistema, as transições viram corte seco.

## Uso

Dependência git (sem publicação no pub.dev ainda):

```yaml
dependencies:
  pillar_ui:
    git:
      url: https://github.com/samuelalvesg/pillar_ui.git
      ref: v0.1.0-alpha.2   # tag SemVer (ver CHANGELOG.md); evite `main`, o pubspec.lock do app fixa o commit e fica velho
```

```dart
import 'package:pillar_ui/pillar_ui.dart';
```

## Licença

[MIT](LICENSE).
