import 'package:material_ui/material_ui.dart';

/// Success and warning colors that the Material `ColorScheme` does not have.
/// Each color comes with its `on*` pair; text on it is at least 4.5:1.
/// Errors use `ColorScheme.error`/`onError`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  static const light = StatusColors(
    success: Color(0xFF1B6E2F),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5100),
    onWarning: Color(0xFFFFFFFF),
  );

  static const dark = StatusColors(
    success: Color(0xFF7FD88F),
    onSuccess: Color(0xFF003914),
    warning: Color(0xFFFFB95C),
    onWarning: Color(0xFF472A00),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  /// Falls back to the light palette when the theme does not register one.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) => StatusColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
  );

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}
