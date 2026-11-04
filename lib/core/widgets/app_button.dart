import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

/// A null [onPressed] disables the button. [isLoading] ignores taps and swaps
/// the label for a spinner, keeping the button's colors and width.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading ? _LoadingLabel(label) : Text(label);
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };
    return IgnorePointer(ignoring: isLoading, child: button);
  }
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0, child: Text(label)),
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DefaultTextStyle.of(context).style.color,
            semanticsLabel: label,
          ),
        ),
      ],
    );
  }
}
