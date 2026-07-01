import 'package:percent/screens/result_screen.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

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
      final q        = questions[i];
      final sel      = selection[i];
      final negDeduct = q.negativeMarks >= 0
          ? q.negativeMarks
          : testModel.negativeMarks;
      if (sel == q.answer) {
        o += q.marks;
      } else if (sel != -1 && negDeduct > 0) {
        o -= negDeduct;
      }
    }
    return o;
  }

  int get _total => questions.fold(0, (s, q) => s + q.marks);

  int get _answered => selection.where((s) => s != -1).length;

  int get _skipped => selection.where((s) => s == -1).length;

  int get _deducted {
    int d = 0;
    for (int i = 0; i < questions.length; i++) {
      final q   = questions[i];
      final sel = selection[i];
      if (sel != -1 && sel != q.answer) {
        final neg = q.negativeMarks >= 0 ? q.negativeMarks : testModel.negativeMarks;
        d += neg;
      }
    }
    return d;
  }

  bool get _hasNegativeMarking =>
      testModel.negativeMarks > 0 ||
      questions.any((q) => q.negativeMarks > 0);

  double get _pct => _total > 0 ? (_obtained.clamp(0, _total) / _total) : 0;

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

  IconData get _resultIcon {
    if (_pct >= 0.7) return Icons.emoji_events_rounded;
    if (_pct >= 0.4) return Icons.thumb_up_rounded;
    return Icons.trending_up_rounded;
  }

  String get _resultSubtitle {
    if (_pct >= 0.7) return 'Great work — you\'ve mastered this one.';
    if (_pct >= 0.4) return 'You\'re getting there. Review and retry.';
    return 'Keep going — review the answers and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTopBar(title: testModel.name),
      body: Column(
        children: [
          const SizedBox(height: AppTheme.space6),
          // Score hero card
          Padding(
            padding: AppTheme.screenPadding,
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space7, horizontal: AppTheme.space6),
              child: Column(
                children: [
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
                                backgroundColor: AppTheme.borderLight,
                              ),
                            );
                          },
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_obtained/$_total',
                              style: TextStyle(
                                  color: _obtained < 0
                                      ? AppTheme.error
                                      : AppTheme.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900)),
                          Text('marks',
                              style: AppTheme.caption),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space5),
                  // Result banner: icon + label + encouraging subtitle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space5, vertical: AppTheme.space4),
                    decoration: BoxDecoration(
                      color: _resultColor.withValues(alpha: 0.10),
                      borderRadius: AppTheme.brMd,
                      border:
                          Border.all(color: _resultColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _resultColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_resultIcon, color: _resultColor, size: 22),
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_resultLabel,
                                  style: AppTheme.headingSm
                                      .copyWith(color: _resultColor)),
                              const SizedBox(height: 2),
                              Text(_resultSubtitle,
                                  style: AppTheme.caption
                                      .copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space7),
          // Stat cards
          Padding(
            padding: AppTheme.screenPadding,
            child: Row(
              children: [
                _StatCard(
                    label: 'Answered',
                    value: '$_answered',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success),
                const SizedBox(width: AppTheme.space4),
                _StatCard(
                    label: 'Skipped',
                    value: '$_skipped',
                    icon: Icons.remove_circle_rounded,
                    color: AppTheme.warning),
                const SizedBox(width: AppTheme.space4),
                if (_hasNegativeMarking) ...[
                  _StatCard(
                      label: 'Deducted',
                      value: '−$_deducted',
                      icon: Icons.indeterminate_check_box_rounded,
                      color: AppTheme.error),
                ] else ...[
                  _StatCard(
                      label: 'Accuracy',
                      value: '${(_pct * 100).round()}%',
                      icon: Icons.analytics_rounded,
                      color: AppTheme.primary),
                ],
              ],
            ),
          ),
          if (_hasNegativeMarking) ...[
            const SizedBox(height: AppTheme.space4),
            Padding(
              padding: AppTheme.screenPadding,
              child: Row(
                children: [
                  _StatCard(
                      label: 'Accuracy',
                      value: '${(_pct * 100).round()}%',
                      icon: Icons.analytics_rounded,
                      color: AppTheme.primary),
                ],
              ),
            ),
          ],
          const Spacer(),
          // CTA buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppTheme.space6, 0, AppTheme.space6,
                MediaQuery.of(context).padding.bottom + AppTheme.space5),
            child: Column(
              children: [
                AppButton(
                  label: 'Review Answers',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultScreen(
                        testModel: testModel,
                        selection: selection,
                        questions: questions,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                AppButton(
                  label: 'Back to Tests',
                  variant: AppButtonVariant.outline,
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
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
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.brLg,
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
