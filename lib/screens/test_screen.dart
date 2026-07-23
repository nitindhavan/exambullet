import 'dart:async';
import 'package:percent/models/question_model.dart';
import 'package:percent/screens/score_screen.dart';
import 'package:percent/services/test_result_service.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/report_sheet.dart';
import 'package:percent/widgets/ui/ui.dart';

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
  DateTime? _startedAt; // when the test actually began, for elapsed-time capture
  bool _saved = false; // guard against double-saving on auto + manual submit
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
          .ref('questions')
          .orderByChild('paperId')
          .equalTo(widget.paperId)
          .once();
      for (final q in snap.snapshot.children) {
        qs.add(Question.fromMap(q.value as Map));
      }
    } else {
      // Load all questions for the test
      final snap = await FirebaseDatabase.instance
          .ref('questions')
          .orderByChild('testId')
          .equalTo(widget.testModel.id)
          .once();
      for (final q in snap.snapshot.children) {
        qs.add(Question.fromMap(q.value as Map));
      }
    }

    if (!mounted) return;
    setState(() {
      _questions = qs;
      _selected = List.filled(qs.length, -1);
      _timerNotifier.value = widget.testModel.time * 60;
      _loaded = true;
    });
    _startedAt = DateTime.now();
    Analytics.instance.logStartTest(widget.testModel.id, widget.examId);
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
    // Persist the attempt for the analytics dashboard (fire-and-forget so the
    // score screen shows immediately). Guarded so auto + manual submit can't
    // both save.
    if (!_saved) {
      _saved = true;
      final elapsedSec = _startedAt == null
          ? widget.testModel.time * 60
          : DateTime.now().difference(_startedAt!).inSeconds;
      TestResultService.saveAttempt(
        test: widget.testModel,
        examId: widget.examId,
        paperId: widget.paperId ?? '',
        questions: _questions,
        selection: _selected,
        elapsedSec: elapsedSec,
      ).then((result) {
        if (result != null) {
          Analytics.instance.logCompleteTest(
            testId: widget.testModel.id,
            examId: widget.examId,
            scorePct: (result.scorePct * 100).round(),
          );
        }
      });
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreScreen(
          selection: _selected,
          questions: _questions,
          testModel: widget.testModel,
          examId: widget.examId,
          paperId: widget.paperId ?? '',
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
                color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'You have answered ${_answeredNotifier.value} of ${_questions.length} questions.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
                    colors: AppTheme.primaryGradient),
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

  void _reportCurrentQuestion() {
    final q = _questions[_current];
    showReportSheet(
      context,
      type: 'question',
      examId: widget.examId,
      testId: widget.testModel.id,
      paperId: widget.paperId ?? '',
      questionId: q.id,
      questionText: q.questionText,
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
      // Keep the real app bar; shimmer only the content area so the page
      // doesn't jump when questions arrive.
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppTopBar(
          title: widget.testModel.name,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: const PercentLoaderCentered(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppTopBar(title: widget.testModel.name),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.quiz_outlined,
                      size: 40, color: AppTheme.primary),
                ),
                const SizedBox(height: AppTheme.space5),
                Text('No questions available', style: AppTheme.headingMd),
                const SizedBox(height: AppTheme.space3),
                Text(
                  'This test currently has no questions added to it.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTopBar(
        title: widget.testModel.name,
        onBack: _confirmFinish,
        actions: [
          Center(child: _TimerChip(timerNotifier: _timerNotifier)),
          const SizedBox(width: AppTheme.space5),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressBar(
            current: _current,
            total: _questions.length,
            answeredNotifier: _answeredNotifier,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.space5, AppTheme.space4, AppTheme.space5, AppTheme.space7),
              children: [
                // ── Question text (light card) ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.space5),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppTheme.brLg,
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: AppTheme.brSm,
                            ),
                            child: Text('Question ${_current + 1}',
                                style: AppTheme.label.copyWith(
                                    color: AppTheme.primary, fontSize: 11.5)),
                          ),
                          const Spacer(),
                          ReportButton(onTap: _reportCurrentQuestion),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        _questions[_current].questionText,
                        style: AppTheme.body.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
                if (_questions[_current].imageUrl.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space4),
                  ClipRRect(
                    borderRadius: AppTheme.brMd,
                    child: Image.network(
                      _questions[_current].imageUrl,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2));
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space6),
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
              ],
            ),
          ),
          // ── Bottom action bar: Prev · Palette · Next / Submit ─────────
          _BottomBar(
            isFirst: _current == 0,
            isLast: _current == _questions.length - 1,
            answeredNotifier: _answeredNotifier,
            total: _questions.length,
            onPrev: () => _goTo(_current - 1),
            onNext: () => _goTo(_current + 1),
            onPalette: () => _showPalette(context),
            onSubmit: _confirmFinish,
          ),
        ],
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

// ── Timer chip (light, for the app bar) ───────────────────────────────────────

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timerNotifier});
  final ValueNotifier<int> timerNotifier;

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
    return ValueListenableBuilder<int>(
      valueListenable: timerNotifier,
      builder: (_, seconds, __) {
        final isLow = seconds <= 60;
        final Color fg = isLow ? AppTheme.error : AppTheme.primary;
        final Color bg =
            isLow ? AppTheme.errorLight : AppTheme.primaryLight;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppTheme.brSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLow ? Icons.warning_amber_rounded : Icons.timer_rounded,
                color: fg,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(_fmt(seconds),
                  style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        );
      },
    );
  }
}

// ── Progress bar (position + answered count) ──────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.current,
    required this.total,
    required this.answeredNotifier,
  });
  final int current;
  final int total;
  final ValueNotifier<int> answeredNotifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space5, AppTheme.space4, AppTheme.space5, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: answeredNotifier,
                  builder: (_, answered, __) => Text(
                    '$answered of $total answered',
                    style: AppTheme.caption
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                Text('Question ${current + 1} of $total',
                    style: AppTheme.label
                        .copyWith(color: AppTheme.primary, fontSize: 12)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? (current + 1) / total : 0,
              backgroundColor: AppTheme.primaryLight,
              color: AppTheme.primary,
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
        margin: const EdgeInsets.only(bottom: AppTheme.space4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          borderRadius: AppTheme.brMd,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.primaryLight,
                borderRadius: AppTheme.brSm,
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(optionText,
                  style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isFirst,
    required this.isLast,
    required this.answeredNotifier,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onPalette,
    required this.onSubmit,
  });
  final bool isFirst;
  final bool isLast;
  final ValueNotifier<int> answeredNotifier;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPalette;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTheme.space5, AppTheme.space4, AppTheme.space5, bottomPad + AppTheme.space4),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          _GhostBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: !isFirst,
            onTap: onPrev,
          ),
          const SizedBox(width: AppTheme.space3),
          // Palette button with live answered count
          Expanded(
            child: GestureDetector(
              onTap: onPalette,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: AppTheme.brMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: answeredNotifier,
                      builder: (_, answered, __) => Text(
                        '$answered / $total',
                        style: AppTheme.label.copyWith(
                            color: AppTheme.primary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          // Next (or Submit on the last question)
          isLast
              ? _PrimaryBtn(
                  label: 'Submit', icon: Icons.check_rounded, onTap: onSubmit)
              : _GhostBtn(
                  icon: Icons.arrow_forward_ios_rounded,
                  enabled: true,
                  onTap: onNext,
                ),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.brMd,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? AppTheme.primary : AppTheme.border),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.brMd,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTheme.label.copyWith(color: Colors.white)),
            const SizedBox(width: 6),
            Icon(icon, color: Colors.white, size: 18),
          ],
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
        color: AppTheme.background,
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
                      color: AppTheme.textPrimary,
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
                    color: AppTheme.success),
                const SizedBox(width: 10),
                _PaletteStat(
                    value: unanswered,
                    label: 'Skipped',
                    color: AppTheme.warning),
                const SizedBox(width: 10),
                _PaletteStat(
                    value: total,
                    label: 'Total',
                    color: AppTheme.primary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? answered / total : 0,
                backgroundColor: AppTheme.borderLight,
                color: AppTheme.success,
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
                  bg = AppTheme.primary;
                  fg = Colors.white;
                } else if (isAnswered) {
                  bg = AppTheme.success.withValues(alpha: 0.15);
                  fg = const Color(0xff065F46);
                } else {
                  bg = Colors.white;
                  fg = AppTheme.textSecondary;
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
                            ? AppTheme.primary
                            : isAnswered
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : AppTheme.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: AppTheme.softShadow,
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
                          const Icon(Icons.check_rounded,
                              size: 10, color: AppTheme.success),
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
                      colors: AppTheme.primaryGradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
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
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
