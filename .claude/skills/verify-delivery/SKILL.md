---
name: verify-delivery
description: Runs the delivery gate of the pillar_ui Flutter package (flutter pub get, flutter analyze, flutter test) and reports PASS, FAIL or NÃO EXECUTADO per command. Use before handing off to @qa-engineer or @reviewer, before marking a PR ready, and whenever someone asks whether it is green.
---

# Verify delivery (pillar_ui)

## Rules
- Detect capability first: `command -v flutter` and `flutter --version`.
  `material_ui` needs **Flutter 3.50.1 or newer** (Dart 3.13+). With an older
  SDK `flutter pub get` fails with "version solving failed"; report
  `NÃO EXECUTADO: Flutter <3.50.1`, never green.
- The repository has no CI workflow, so this local run is the only evidence.
- Never skip, weaken or delete a test to get green.
- While fixing, re-run only the failing test file; the full gate at the end.
- Keep only failures, totals and skip lines.

## Commands (repo root)
1. `flutter pub get`
2. `flutter analyze`. Baseline measured 2026-11-22 (Flutter 3.50.1): 9 infos,
   all "Dangling library doc comment"; only new issues count.
3. `flutter test` (21 tests passed on 2026-11-22)

Plugin `dart-flutter` (declared in `.claude/settings.json`) helps while
working; the gate is the real `flutter analyze` and `flutter test`.

## Report (same block in the PR body)
```
VERIFY: pillar_ui @ <short sha>
flutter --version → <version>
flutter pub get → PASS | FAIL | NÃO EXECUTADO: <motivo>
flutter analyze → PASS (<n> infos) | FAIL (<n> errors/warnings)
flutter test → PASS | FAIL (<passed>/<failed>/<skipped>)
```
