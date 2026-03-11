import 'package:percent/screens/result_screen.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';

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
    if (_pct >= 0.7) return const Color(0xff4CAF50);
    if (_pct >= 0.4) return const Color(0xffFF9800);
    return const Color(0xffF44336);
  }

  String get _resultLabel {
    if (_pct >= 0.7) return 'Excellent!';
    if (_pct >= 0.4) return 'Good Attempt';
    return 'Keep Practising';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0EBFF),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1E0845), Color(0xff4A1E96)],
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
                          child: CircularProgressIndicator(
                            value: _pct,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            color: _resultColor,
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
                    color: const Color(0xff4CAF50)),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Skipped',
                    value: '$_skipped',
                    icon: Icons.remove_circle_rounded,
                    color: const Color(0xffFF9800)),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Accuracy',
                    value: '${(_pct * 100).round()}%',
                    icon: Icons.analytics_rounded,
                    color: const Color(0xff3D1975)),
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
                          colors: [Color(0xff1E0845), Color(0xff4A1E96)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xff3D1975).withOpacity(0.3),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Back to Tests',
                          style: TextStyle(
                              color: Color(0xff3D1975),
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
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
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
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
