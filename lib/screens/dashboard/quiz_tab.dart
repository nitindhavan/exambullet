import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/membership_screen.dart';

class QuizTab extends StatefulWidget {
  const QuizTab(
      {Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    if (widget.hasMembership) _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final snap = await FirebaseDatabase.instance
        .ref('quickquizzes')
        .child(widget.exam.id)
        .once();
    if (!mounted) return;
    List<Map<String, dynamic>> qs = [];
    if (snap.snapshot.value != null) {
      final raw = snap.snapshot.value as Map;
      qs = raw.values
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList()
        ..shuffle();
    }
    setState(() {
      _questions = qs;
      _loading = false;
    });
  }

  void _select(int idx) {
    if (_answered) return;
    final correct = _questions[_currentIndex]['correctIndex'] as int;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      if (idx == correct) _score++;
    });
  }

  void _next() {
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restart() {
    final shuffled = List<Map<String, dynamic>>.from(_questions)..shuffle();
    setState(() {
      _questions = shuffled;
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasMembership) {
      return _LockedState(
        onUnlock: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MemberShipScreen(model: widget.exam.id))),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xff3D1975)));
    }
    if (_questions.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outlined,
        title: 'No practice questions',
        subtitle: 'Quick practice questions will appear here soon.',
      );
    }
    if (_currentIndex >= _questions.length) {
      return _ResultCard(
          score: _score, total: _questions.length, onRestart: _restart);
    }

    final q = _questions[_currentIndex];
    final options = (q['options'] as List).cast<String>();
    final correct = q['correctIndex'] as int;
    final tag = q['tag'] as String? ?? '';
    final explanation = q['explanation'] as String? ?? '';

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${_currentIndex + 1} / ${_questions.length}',
                      style: const TextStyle(
                          color: Color(0xff2D0F5E),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color:
                              const Color(0xff3D1975).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(tag,
                          style: const TextStyle(
                              color: Color(0xff3D1975),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor:
                      const Color(0xff3D1975).withOpacity(0.1),
                  color: const Color(0xff3D1975),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff3D1975), Color(0xff6B3FA0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xff3D1975).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Text(q['question'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5)),
                ),
                const SizedBox(height: 16),
                // Options
                ...options.asMap().entries.map((e) {
                  final idx = e.key;
                  final opt = e.value;
                  Color bg = Colors.white;
                  Color borderColor = Colors.grey.shade200;
                  Color textColor = const Color(0xff1A0540);
                  if (_answered) {
                    if (idx == correct) {
                      bg = const Color(0xffE8F5E9);
                      borderColor = const Color(0xff4CAF50);
                      textColor = const Color(0xff2E7D32);
                    } else if (idx == _selectedOption) {
                      bg = const Color(0xffFFEBEE);
                      borderColor = const Color(0xffF44336);
                      textColor = const Color(0xffC62828);
                    }
                  }
                  return GestureDetector(
                    onTap: () => _select(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _answered && idx == correct
                                  ? const Color(0xff4CAF50)
                                      .withOpacity(0.15)
                                  : _answered && idx == _selectedOption
                                      ? const Color(0xffF44336)
                                          .withOpacity(0.15)
                                      : const Color(0xff3D1975)
                                          .withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                    color: borderColor ==
                                            Colors.grey.shade200
                                        ? const Color(0xff3D1975)
                                        : borderColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(opt,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500))),
                          if (_answered && idx == correct)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xff4CAF50), size: 20)
                          else if (_answered &&
                              idx == _selectedOption)
                            const Icon(Icons.cancel_rounded,
                                color: Color(0xffF44336), size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                // Explanation
                if (_answered && explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_rounded,
                            color: Color(0xffF9A825), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(explanation,
                              style: const TextStyle(
                                  color: Color(0xff5D4037),
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ],
                // Next button
                if (_answered) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _currentIndex < _questions.length - 1
                              ? 'Next Question →'
                              : 'See Results',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.score, required this.total, required this.onRestart});
  final int score;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xff3D1975).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: Text('$pct%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Session Complete!',
                style: TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('$score out of $total correct',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Practice Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.onUnlock});
  final VoidCallback onUnlock;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Pro Content',
                style: TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Unlock practice quizzes with a Pro membership.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onUnlock,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Unlock Pro',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.06),
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 40,
                  color: const Color(0xff3D1975).withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}