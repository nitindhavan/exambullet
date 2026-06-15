import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/subject_model.dart';
import 'package:percent/models/topic_model.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer.dart';

// ══════════════════════════════════════════════════════════════════════════════
// QuizTab  —  subjects list
// ══════════════════════════════════════════════════════════════════════════════

class QuizTab extends StatefulWidget {
  const QuizTab({Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<SubjectModel> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final snap = await FirebaseDatabase.instance
        .ref('subjects')
        .orderByChild('examId')
        .equalTo(widget.exam.id)
        .once();
    if (!mounted) return;
    List<SubjectModel> list = [];
    if (snap.snapshot.value != null) {
      final raw = snap.snapshot.value as Map;
      list = raw.values.map((v) => SubjectModel.fromMap(v as Map)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() {
      _subjects = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ShimmerLoading(
        builder: (context, color) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      );
    }
    if (_subjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        subtitle: 'Practice subjects will appear here soon.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text('Choose a Subject',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: _subjects.length,
            itemBuilder: (_, i) {
              final subject = _subjects[i];
              final color = _subjectColors[i % _subjectColors.length];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _TopicsScreen(subject: subject),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: color, width: 4),
                      top: const BorderSide(color: AppTheme.borderLight),
                      right: const BorderSide(color: AppTheme.borderLight),
                      bottom: const BorderSide(color: AppTheme.borderLight),
                    ),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(11)),
                        child: Icon(Icons.menu_book_rounded,
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(subject.name,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

const _subjectColors = [
  Color(0xff10B981), // Emerald
  Color(0xff3B82F6), // Blue
  Color(0xffF59E0B), // Amber
  Color(0xff8B5CF6), // Violet
  Color(0xffEF4444), // Red
  Color(0xff06B6D4), // Cyan
  Color(0xffEC4899), // Pink
  Color(0xffF97316), // Orange
];

// ══════════════════════════════════════════════════════════════════════════════
// Topics screen
// ══════════════════════════════════════════════════════════════════════════════

class _TopicsScreen extends StatefulWidget {
  const _TopicsScreen({required this.subject});
  final SubjectModel subject;

  @override
  State<_TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<_TopicsScreen> {
  List<TopicModel> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final snap = await FirebaseDatabase.instance
        .ref('topics')
        .orderByChild('subjectId')
        .equalTo(widget.subject.id)
        .once();
    if (!mounted) return;
    List<TopicModel> list = [];
    if (snap.snapshot.value != null) {
      final raw = snap.snapshot.value as Map;
      list = raw.values.map((v) => TopicModel.fromMap(v as Map)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() {
      _topics = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? ShimmerLoading(
                    builder: (context, color) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (_, __) => Container(
                          height: 64,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    },
                  )
                : _topics.isEmpty
                    ? const _EmptyState(
                        icon: Icons.topic_outlined,
                        title: 'No topics yet',
                        subtitle: 'Topics will appear here soon.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _topics.length,
                        itemBuilder: (_, i) {
                          final topic = _topics[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _QuizPlayerScreen(topic: topic),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderLight),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(9)),
                                    child: const Icon(Icons.bolt_rounded,
                                        color: AppTheme.primary, size: 18),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(topic.name,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Practice',
                                            style: TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 12, color: AppTheme.primary),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 16, 20),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Topics',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(widget.subject.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quiz player  (per topic)
// ══════════════════════════════════════════════════════════════════════════════

class _QuizPlayerScreen extends StatefulWidget {
  const _QuizPlayerScreen({required this.topic});
  final TopicModel topic;

  @override
  State<_QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<_QuizPlayerScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final snap = await FirebaseDatabase.instance
        .ref('quizzes')
        .orderByChild('topicId')
        .equalTo(widget.topic.id)
        .once();
    if (!mounted) return;
    List<Map<String, dynamic>> qs = [];
    if (snap.snapshot.value != null) {
      final raw = snap.snapshot.value as Map;
      qs = raw.values.map((v) => Map<String, dynamic>.from(v as Map)).toList()
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

  void _next() => setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });

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
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 16, 20),
                child: Row(
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
                      child: Text(widget.topic.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_questions.isEmpty) {
      return const _EmptyState(
        icon: Icons.quiz_outlined,
        title: 'No questions yet',
        subtitle: 'Questions for this topic will appear soon.',
      );
    }
    if (_currentIndex >= _questions.length) {
      return _ResultCard(
          score: _score, total: _questions.length, onRestart: _restart);
    }

    final q = _questions[_currentIndex];
    final options = (q['options'] as List).cast<String>();
    final correct = q['correctIndex'] as int;
    final explanation = q['explanation'] as String? ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: AppTheme.primaryLight,
                  color: AppTheme.primary,
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
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
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
                  Color borderColor = AppTheme.borderLight;
                  Color textColor = AppTheme.textPrimary;
                  if (_answered) {
                    if (idx == correct) {
                      bg = AppTheme.successLight;
                      borderColor = AppTheme.success;
                      textColor = const Color(0xff065F46);
                    } else if (idx == _selectedOption) {
                      bg = AppTheme.errorLight;
                      borderColor = AppTheme.error;
                      textColor = const Color(0xff991B1B);
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
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _answered && idx == correct
                                  ? AppTheme.success.withOpacity(0.15)
                                  : _answered && idx == _selectedOption
                                      ? AppTheme.error.withOpacity(0.15)
                                      : AppTheme.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                    color: borderColor == AppTheme.borderLight
                                        ? AppTheme.primary
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
                                color: AppTheme.success, size: 20)
                          else if (_answered && idx == _selectedOption)
                            const Icon(Icons.cancel_rounded,
                                color: AppTheme.error, size: 20),
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
                       color: AppTheme.warningLight,
                       borderRadius: BorderRadius.circular(14),
                       border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                     ),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Icon(Icons.info_rounded,
                             color: AppTheme.warning, size: 18),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Text(explanation,
                               style: const TextStyle(
                                   color: AppTheme.textPrimary,
                                   fontSize: 13,
                                   height: 1.5)),
                         ),
                       ],
                     ),
                  ),
                ],
                if (_answered) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppTheme.primaryGradient),
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

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

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
                    colors: AppTheme.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
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
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('$score out of $total correct',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: AppTheme.primaryGradient),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Pro Content',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Unlock practice quizzes with a Pro membership.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onUnlock,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient),
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
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 40, color: AppTheme.primary.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
