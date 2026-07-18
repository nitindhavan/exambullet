import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

/// Branded loading indicator: a "%" symbol that fills like WATER — a wavy liquid
/// surface rises from the bottom with the brand gradient, ripples, then repeats.
/// Replaces spinners/shimmers app-wide. Always centered.
class PercentLoader extends StatefulWidget {
  const PercentLoader({Key? key, this.size = 56, this.label}) : super(key: key);

  final double size;
  final String? label;

  @override
  State<PercentLoader> createState() => _PercentLoaderState();
}

class _PercentLoaderState extends State<PercentLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: s,
            height: s,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value; // 0..1 loop
                // Fill level rises and gently recedes for a breathing loop.
                final rise = 0.5 - 0.5 * math.cos(t * 2 * math.pi); // 0→1→0
                final level = 0.12 + rise * 0.82; // never fully empty/full
                return CustomPaint(
                  size: Size(s, s),
                  painter: _WaterPainter(
                    level: level,
                    phase: t * 2 * math.pi,
                  ),
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 14),
            Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Paints a rising, wavy water fill and clips it to a "%" glyph.
class _WaterPainter extends CustomPainter {
  _WaterPainter({required this.level, required this.phase});
  final double level; // 0 (empty) .. 1 (full)
  final double phase; // wave animation phase

  TextPainter _glyph(double h, Color color) {
    return TextPainter(
      text: TextSpan(
        text: '%',
        style: TextStyle(
          fontSize: h,
          height: 1,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // 1) Faint empty "%" so the shape is always visible (the water container).
    final faint = _glyph(h, AppTheme.primary.withValues(alpha: 0.13));
    final gx = (w - faint.width) / 2;
    final gy = (h - faint.height) / 2;
    faint.paint(canvas, Offset(gx, gy));

    // 2) Water layer: draw the wavy gradient fill, then mask it to the glyph.
    canvas.saveLayer(Offset.zero & size, Paint());

    final baseY = h * (1 - level);
    final amplitude = h * 0.05;
    final wave = Path()..moveTo(0, h);
    wave.lineTo(0, baseY);
    const steps = 26;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final y = baseY +
          math.sin(phase + (i / steps) * 2 * math.pi * 1.6) * amplitude +
          math.sin(phase * 1.4 + (i / steps) * 2 * math.pi * 2.5) *
              amplitude *
              0.5;
      wave.lineTo(x, y);
    }
    wave.lineTo(w, h);
    wave.close();

    final gradient = const LinearGradient(
      colors: AppTheme.primaryGradient,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Offset.zero & size);
    canvas.drawPath(wave, Paint()..shader = gradient);

    // Mask: keep water only where the "%" glyph is opaque.
    final mask = _glyph(h, Colors.white);
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.dstIn);
    mask.paint(canvas, Offset(gx, gy));
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.level != level || old.phase != phase;
}

/// Centered [PercentLoader] for full-page loading spots.
class PercentLoaderCentered extends StatelessWidget {
  const PercentLoaderCentered({Key? key, this.label}) : super(key: key);
  final String? label;

  @override
  Widget build(BuildContext context) =>
      Center(child: PercentLoader(size: 56, label: label));
}
