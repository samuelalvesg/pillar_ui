import 'package:material_ui/material_ui.dart';

/// Shared motion tokens. Every animated widget of the package resolves its
/// duration through [duration] so "reduce motion" turns movement into a cut.
abstract final class AppMotion {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration long = Duration(milliseconds: 300);

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOut;

  /// [base], or [Duration.zero] when the platform asks to disable animations.
  static Duration duration(BuildContext context, Duration base) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
}

/// `AnimatedSize` that becomes a plain cut when [duration] is zero.
/// `AnimatedSize` asserts when its size changes with a zero duration, which
/// is exactly what "reduce motion" produces.
class AnimatedSizeOrCut extends StatelessWidget {
  const AnimatedSizeOrCut({
    super.key,
    required this.duration,
    required this.curve,
    this.alignment = Alignment.center,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
