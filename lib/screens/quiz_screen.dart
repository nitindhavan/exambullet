import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/subject_model.dart';
import 'package:percent/models/topic_model.dart';
import 'package:percent/screens/membership_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// QuizTab  —  entry point (subjects list)
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
    if (widget.hasMembership) _loadSubjects();
    else _loading = false;
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
      list = raw.values
          .map((v) => SubjectModel.fromMap(v as Map))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() {
      _subjects = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasMembership) {
      return _LockedState(
        onUnlock: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MemberShipScreen(model: widget.exam.id)),
        ),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xff3D1975)));
    }
    if (_subjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outlined,
        title: 'No subjects yet',
        subtitle: 'Practice subjects will appear here soon.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text('Subjects',
              style: TextStyle(
                  color: Color(0xff2D0F5E),
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _subjects.length,
            itemBuilder: (_, i) => _SubjectCard(
              subject: _subjects[i],
              index: i,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _TopicsScreen(
                    subject: _subjects[i],
                    examId: widget.exam.id,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Subject card
// ══════════════════════════════════════════════════════════════════════════════

class _SubjectCard extends StatelessWidget {
  const _SubjectCard(
      {required this.subject, required this.index, required this.onTap});
  final SubjectModel subject;
  final int index;
  final VoidCallback onTap;

  static const _colors = [
    Color(0xff4CAF50),
    Color(0xff2196F3),
    Color(0xffFF9800),
    Color(0xff9C27B0),
    Color(0xffF44336),
    Color(0xff00BCD4),
    Color(0xffE91E63),
    Color(0xff795548),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.menu_book_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(subject.name,
                  style: const TextStyle(
                      color: Color(0xff1A0540),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Topics screen
// ══════════════════════════════════════════════════════════════════════════════

class _TopicsScreen extends StatefulWidget {
  const _TopicsScreen({required this.subject, required this.examId});
  final SubjectModel subject;
  final String examId;

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
      list = raw.values
          .map((v) => TopicModel.fromMap(v as Map))
          .toList()
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
      backgroundColor: const Color(0xffF6F2FF),
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
                      child: Text(widget.subject.name,
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
          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xff3D1975)))
                : _topics.isEmpty
                    ? const _EmptyState(
                        icon: Icons.topic_outlined,
                        title: 'No topics yet',
                        subtitle: 'Topics will appear here soon.')
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        itemCount: _topics.length,
                        itemBuilder: (_, i) => _TopicCard(
                          topic: _topics[i],
                          index: i,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _QuizPlayerScreen(
                                topic: _topics[i],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Topic card
// ══════════════════════════════════════════════════════════════════════════════

class _TopicCard extends StatelessWidget {
  const _TopicCard(
      {required this.topic, required this.index, required this.onTap});
  final TopicModel topic;
  final int index;
  final VoidCallback onTap;

  static const _icons = [
    Icons.bolt_rounded,
    Icons.psychology_rounded,
    Icons.calculate_rounded,
    Icons.translate_rounded,
    Icons.science_rounded,
    Icons.history_edu_rounded,
    Icons.public_rounded,
    Icons.biotech_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(_icons[index % _icons.length],
                  color: const Color(0xff3D1975), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(topic.name,
                  style: const TextStyle(
                      color: Color(0xff1A0540),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Practice',
                      style: TextStyle(
                          color: Color(0xff3D1975),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: Color(0xff3D1975)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quiz player screen  (per topic)
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
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
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
          // Body
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xff3D1975)));
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
          score: _score,
          total: _questions.length,
          onRestart: _restart);
    }

    final q = _questions[_currentIndex];
    final options = (q['options'] as List).cast<String>();
    final correct = q['correctIndex'] as int;
    final explanation = q['explanation'] as String? ?? '';

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                      color: Color(0xff2D0F5E),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
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
                          color: const Color(0xff3D1975).withOpacity(0.25),
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
                  IconData? trailingIcon;
                  if (_answered) {
                    if (idx == correct) {
                      bg = const Color(0xffE8F5E9);
                      borderColor = const Color(0xff4CAF50);
                      textColor = const Color(0xff2E7D32);
                      trailingIcon = Icons.check_circle_rounded;
                    } else if (idx == _selectedOption) {
                      bg = const Color(0xffFFEBEE);
                      borderColor = const Color(0xffF44336);
                      textColor = const Color(0xffC62828);
                      trailingIcon = Icons.cancel_rounded;
                    }
                  }
                  return GestureDetector(
                    onTap: () => _select(idx),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor)),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(opt,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500))),
                          if (trailingIcon != null)
                            Icon(trailingIcon, color: borderColor, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                // Explanation
                if (_answered && explanation.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xffE3F2FD),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xff1565C0), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(explanation,
                              style: const TextStyle(
                                  color: Color(0xff1565C0),
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                // Next button
                if (_answered)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff3D1975),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _currentIndex + 1 < _questions.length
                              ? 'Next Question'
                              : 'See Results',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.score, required this.total, required this.onRestart});
  final int score;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (score / total * 100).round();
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
                color: pct >= 60
                    ? const Color(0xffE8F5E9)
                    : const Color(0xffFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$pct%',
                    style: TextStyle(
                        color: pct >= 60
                            ? const Color(0xff2E7D32)
                            : const Color(0xffC62828),
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            Text('$score / $total correct',
                style: const TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3D1975),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded,
                  color: Color(0xff3D1975), size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Premium Content',
                style: TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Get membership to access practice questions.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3D1975),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Get Membership',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}