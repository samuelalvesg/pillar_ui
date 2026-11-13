## 0.1.0-alpha.1

* Migra de `flutter/material` para `material_ui` (Flutter 3.50). Quem usa o pacote precisa do Flutter 3.50 e passa a receber o `ThemeData` do `material_ui`.
* `AdaptiveNavigationItem` ganha `badgeCount` (`int`, padrão `0`) - contador
  (`Badge.count`) sobre o ícone no rail e na barra inferior.
* `AdaptiveNavigationScaffold` ganha `titleWidget` (`Widget?`) - título
  rico, vence sobre `title` (`String?`) quando os dois são passados.

## 0.0.1

* TODO: Describe initial release.
