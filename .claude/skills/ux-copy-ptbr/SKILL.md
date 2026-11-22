---
name: ux-copy-ptbr
description: Brazilian Portuguese (pt-BR) interface copy guidelines (buttons, errors, empty states, confirmation dialogs). Use when writing or reviewing user-facing UI strings for pt-BR locales.
---
# Rules
- Brazilian Portuguese (pt-BR) with full diacritics and correct spelling; never ASCII substitutions ("nao", "acao").
- Consistent terminology: maintain domain vocabulary throughout screens.
- Action-oriented buttons: use clear infinitive verbs ("Salvar alterações", "Criar equipe", not vague "OK", "Enviar").
- Errors: what happened + why (if helpful) + what to do next. Never display raw technical stack traces or internal exception classes to users.
- Empty states: identify what the view represents + explain why it is empty + explain how to begin.
- Confirmations: clearly name the action and its consequences ("Excluir 3 arquivos? Essa ação não pode ser desfeita.").
- Loading states: convey realistic expectations without promising exact seconds.
- Tone: professional, respectful, concise, and helpful.

# Code Convention
- Code identifiers and localization keys MUST be in English (e.g. `user_profile.save_changes_button`).
- User-facing values in pt-BR localization files.

# Output Format
`ELEMENT | localized_copy | notes`
