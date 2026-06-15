import 'package:percent/screens/result_screen.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import 'package:percent/utils/theme.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({
    Key? key,
    required this.testModel,
    required this.selection,
    required this.questions,
  }) : super(key: key);

  final TestModel testModel;
  final List<int> selection;
  final List<Question> questions;

  int get _obtained {
    int o = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selection[i] == questions[i].answer) o += questions[i].marks;
    }
    return o;
  }

  int get _total => questions.fold(0, (s, q) => s + q.marks);

  int get _answered => selection.where((s) => s != -1).length;

  int get _skipped => selection.where((s) => s == -1).length;

  double get _pct => _total > 0 ? (_obtained / _total) : 0;

  Color get _resultColor {
    if (_pct >= 0.7) return AppTheme.success;
    if (_pct >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _resultLabel {
    if (_pct >= 0.7) return 'Excellent!';
    if (_pct >= 0.4) return 'Good Attempt';
    return 'Keep Practising';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(testModel.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Score ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1400),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: _pct),
                            builder: (context, value, child) {
                              return CustomPaint(
                                painter: _ScoreRingPainter(
                                  percentage: value,
                                  color: _resultColor,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                ),
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_obtained/$_total',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900)),
                            Text('marks',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _resultColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _resultColor.withOpacity(0.5)),
                      ),
                      child: Text(_resultLabel,
                          style: TextStyle(
                              color: _resultColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatCard(
                    label: 'Answered',
                    value: '$_answered',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Skipped',
                    value: '$_skipped',
                    icon: Icons.remove_circle_rounded,
                    color: AppTheme.warning),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Accuracy',
                    value: '${(_pct * 100).round()}%',
                    icon: Icons.analytics_rounded,
                    color: AppTheme.primary),
              ],
            ),
          ),
          const Spacer(),
          // CTA buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultScreen(
                        testModel: testModel,
                        selection: selection,
                        questions: questions,
                      ),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppTheme.primaryGradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: const Center(
                      child: Text('Review Answers',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Center(
                      child: Text('Back to Tests',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -pi/2
      percentage * 2 * 3.14159,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
