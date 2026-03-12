import 'dart:async';
import 'package:percent/models/question_model.dart';
import 'package:percent/screens/score_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({
    Key? key,
    required this.testModel,
    required this.examId,
    this.paperId,
  }) : super(key: key);
  final TestModel testModel;
  final String examId;
  final String? paperId;
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _current = 0;
  List<int> _selected = [];
  List<Question> _questions = [];
  bool _loaded = false;
  Timer? _timer;
  late final ScrollController _scrollController = ScrollController();

  // ValueNotifiers — update WITHOUT calling setState on the whole tree
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _answeredNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final List<Question> qs = [];

    if (widget.paperId != null) {
      // Load only the selected paper's questions
      final snap = await FirebaseDatabase.instance
          .ref(
              'exams/${widget.examId}/tests/${widget.testModel.id}/papers/${widget.paperId}/questions')
          .once();
      for (final q in snap.snapshot.children) {
        qs.add(Question.fromMap(q.value as Map));
      }
    } else {
      // Load all papers (original behaviour)
      final papersSnap = await FirebaseDatabase.instance
          .ref('exams/${widget.examId}/tests/${widget.testModel.id}/papers')
          .once();
      for (final paper in papersSnap.snapshot.children) {
        for (final q in paper.child('questions').children) {
          qs.add(Question.fromMap(q.value as Map));
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _questions = qs;
      _selected = List.filled(qs.length, -1);
      _timerNotifier.value = widget.testModel.time * 60;
      _loaded = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerNotifier.value <= 0) {
        _timer?.cancel();
        _finish();
        return;
      }
      _timerNotifier.value--; // ← no setState, only notifier update
    });
  }

  void _finish() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreScreen(
          selection: _selected,
          questions: _questions,
          testModel: widget.testModel,
        ),
      ),
    );
  }

  void _confirmFinish() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Test?',
            style: TextStyle(
                color: Color(0xff1E0845), fontWeight: FontWeight.w800)),
        content: Text(
          'You have answered ${_answeredNotifier.value} of ${_questions.length} questions.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade500)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _finish();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff1E0845), Color(0xff4A1E96)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Submit',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _goTo(int index) {
    setState(() => _current = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _timerNotifier.dispose();
    _answeredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xffF0EBFF),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xff3D1975))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF0EBFF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TestHeader(
            testName: widget.testModel.name,
            timerNotifier: _timerNotifier,
            answeredNotifier: _answeredNotifier,
            total: _questions.length,
            onFinish: _confirmFinish,
            onBack: _confirmFinish,
          ),
          _ProgressBar(current: _current, total: _questions.length),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ── Question text ───────────────────────────────────────
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
                          color: const Color(0xff3D1975).withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    _questions[_current].questionText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                  ),
                ),
                if (_questions[_current].imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _questions[_current].imageUrl,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff3D1975), strokeWidth: 2));
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
// ── Options A–D ─────────────────────────────────────────
                ...[1, 2, 3, 4].map((opt) => _OptionButton(
                      label: String.fromCharCode(64 + opt),
                      optionText: _questions[_current].optionText(opt),
                      optionNumber: opt,
                      selected: _selected[_current],
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected[_current] = opt);
                        _answeredNotifier.value =
                            _selected.where((s) => s != -1).length;
                      },
                    )),
                const SizedBox(height: 8),
                // ── Prev / Next ─────────────────────────────────────────
                Row(
                  children: [
                    _NavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Prev',
                      enabled: _current > 0,
                      trailing: false,
                      onTap: () => _goTo(_current - 1),
                    ),
                    const SizedBox(width: 12),
                    _NavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'Next',
                      enabled: _current < _questions.length - 1,
                      trailing: true,
                      onTap: () => _goTo(_current + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _answeredNotifier,
        builder: (_, answered, __) => FloatingActionButton.extended(
          backgroundColor: const Color(0xff3D1975),
          onPressed: () => _showPalette(context),
          icon: const Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 20),
          label: Text(
            '$answered/${_questions.length}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }

  void _showPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuestionPalette(
        total: _questions.length,
        selected: _selected,
        current: _current,
        onTap: (i) {
          Navigator.pop(context);
          _goTo(i);
        },
        onSubmit: () {
          Navigator.pop(context);
          _confirmFinish();
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TestHeader extends StatelessWidget {
  const _TestHeader({
    required this.testName,
    required this.timerNotifier,
    required this.answeredNotifier,
    required this.total,
    required this.onFinish,
    required this.onBack,
  });
  final String testName;
  final ValueNotifier<int> timerNotifier;
  final ValueNotifier<int> answeredNotifier;
  final int total;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  String _fmt(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1E0845), Color(0xff4A1E96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(testName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 3),
                // Only this Text rebuilds when answered changes
                ValueListenableBuilder<int>(
                  valueListenable: answeredNotifier,
                  builder: (_, answered, __) => Text(
                    '$answered / $total answered',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Only this chip rebuilds every second
          ValueListenableBuilder<int>(
            valueListenable: timerNotifier,
            builder: (_, seconds, __) {
              final isLow = seconds <= 60;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xffFF5722)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isLow
                          ? const Color(0xffFF5722)
                          : Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.timer_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(_fmt(seconds),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFinish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Submit',
                  style: TextStyle(
                      color: Color(0xff1E0845),
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Q ${current + 1} of $total',
                style: const TextStyle(
                    color: Color(0xff3D1975),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? (current + 1) / total : 0,
              backgroundColor: const Color(0xff3D1975).withOpacity(0.1),
              color: const Color(0xff3D1975),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option button ─────────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.optionText,
    required this.optionNumber,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String optionText;
  final int optionNumber;
  final int selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == optionNumber;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff3D1975) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xff3D1975) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xff3D1975).withOpacity(0.22)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xff3D1975).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xff3D1975),
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(optionText,
                  style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xff1A0540),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
// ── Nav button ────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final bool trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!trailing)
                Icon(icon,
                    size: 15,
                    color: enabled
                        ? const Color(0xff3D1975)
                        : Colors.grey.shade300),
              if (!trailing) const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: enabled
                          ? const Color(0xff3D1975)
                          : Colors.grey.shade300,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (trailing) const SizedBox(width: 6),
              if (trailing)
                Icon(icon,
                    size: 15,
                    color: enabled
                        ? const Color(0xff3D1975)
                        : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Question palette ──────────────────────────────────────────────────────────

class _QuestionPalette extends StatelessWidget {
  const _QuestionPalette({
    required this.total,
    required this.selected,
    required this.current,
    required this.onTap,
    required this.onSubmit,
  });
  final int total;
  final List<int> selected;
  final int current;
  final ValueChanged<int> onTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final answered = selected.where((s) => s != -1).length;
    final unanswered = total - answered;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Color(0xffF6F2FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Questions',
                  style: TextStyle(
                      color: Color(0xff1E0845),
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _PaletteStat(
                    value: answered,
                    label: 'Answered',
                    color: const Color(0xff4CAF50)),
                const SizedBox(width: 10),
                _PaletteStat(
                    value: unanswered,
                    label: 'Skipped',
                    color: const Color(0xffFF9800)),
                const SizedBox(width: 10),
                _PaletteStat(
                    value: total,
                    label: 'Total',
                    color: const Color(0xff3D1975)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? answered / total : 0,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xff4CAF50),
                minHeight: 7,
              ),
            ),
          ),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                final isCurrent = i == current;
                final isAnswered = selected[i] != -1;
                Color bg;
                Color fg;
                if (isCurrent) {
                  bg = const Color(0xff3D1975);
                  fg = Colors.white;
                } else if (isAnswered) {
                  bg = const Color(0xff4CAF50).withOpacity(0.15);
                  fg = const Color(0xff2E7D32);
                } else {
                  bg = Colors.white;
                  fg = Colors.grey.shade500;
                }
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xff3D1975)
                            : isAnswered
                                ? const Color(0xff4CAF50).withOpacity(0.4)
                                : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${i + 1}',
                            style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        if (isAnswered && !isCurrent)
                          Icon(Icons.check_rounded,
                              size: 10, color: const Color(0xff4CAF50)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 16),
            child: GestureDetector(
              onTap: onSubmit,
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
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                  child: Text('Submit Test ($answered/$total)',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteStat extends StatelessWidget {
  const _PaletteStat(
      {required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
