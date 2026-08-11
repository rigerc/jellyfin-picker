import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';

/// Adds a small, transform-only press response to an interactive child.
final class CandyBounce extends StatefulWidget {
  const CandyBounce({required this.child, this.onPressed, super.key});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<CandyBounce> createState() => _CandyBounceState();
}

final class _CandyBounceState extends State<CandyBounce> {
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant CandyBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null && _pressed) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isPressed = enabled && _pressed;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: disableAnimations || !isPressed ? 1 : 0.96,
          duration: disableAnimations ? Duration.zero : CandyMotion.quick,
          curve: isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (!mounted || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }
}
