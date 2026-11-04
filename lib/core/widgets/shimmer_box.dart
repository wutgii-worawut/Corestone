import 'package:corestone/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A loading placeholder with a highlight sweeping left to right.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({this.width, this.height, this.radius = 8, super.key});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(widget.radius);
    if (MediaQuery.disableAnimationsOf(context)) {
      return _box(
        BoxDecoration(color: colors.shimmerBase, borderRadius: radius),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = _controller.value * 4 - 2;
        return _box(
          BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [
                colors.shimmerBase,
                colors.shimmerHighlight,
                colors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box(BoxDecoration decoration) => DecoratedBox(
    decoration: decoration,
    child: SizedBox(width: widget.width, height: widget.height),
  );
}
