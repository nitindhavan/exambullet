import 'package:flutter/material.dart';

/// A shimmer effect that builds its skeleton subtree **once** and sweeps a
/// moving highlight across it via a [ShaderMask].
///
/// The [builder] receives a [color] to paint the skeleton shapes with (kept for
/// backwards compatibility with existing call-sites). The subtree returned by
/// [builder] is cached and only rebuilt when its inputs change — the animation
/// runs entirely in the shader, so the layout is not re-run every frame.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({Key? key, required this.builder}) : super(key: key);
  final Widget Function(BuildContext context, Color color) builder;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Base skeleton colour: the shapes are painted with this, the shader sweeps a
  // lighter highlight across them.
  static const Color _base = Color(0xffE9EEF4);
  static const Color _highlight = Color(0xffF7FAFC);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the skeleton subtree exactly once — the shimmer is applied on top
    // as a shader, so this does not rebuild on every animation frame.
    final child = widget.builder(context, _base);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, cachedChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width;
            // Slide a diagonal highlight band from left (-1) to right (+2).
            final t = _ctrl.value * 3 - 1;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [_base, _highlight, _base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(t * dx),
            ).createShader(bounds);
          },
          child: cachedChild,
        );
      },
      child: child,
    );
  }
}

/// Translates a gradient horizontally by [dx] pixels.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
