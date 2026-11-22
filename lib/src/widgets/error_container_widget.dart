/// ==============================================
/// Symmetris - Plataforma Multiutilidades
/// ==============================================
///
/// Arquivo: error_container_widget.dart
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

import 'package:material_ui/material_ui.dart';

import '../themes/app_spacing.dart';

/// Inline error message. Announced to screen readers when it appears.
/// Pass both [onRetry] and [retryLabel] to offer a recovery action; the
/// label comes from the caller so the package fixes no language.
class ErrorContainerWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorContainerWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showRetry = onRetry != null && retryLabel != null;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md - 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.md - 4),
          border: Border.all(color: scheme.error),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: Text(
                errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            if (showRetry)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(retryLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
