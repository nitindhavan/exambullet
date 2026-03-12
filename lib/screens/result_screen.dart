import 'package:percent/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    Key? key,
    required this.testModel,
    required this.selection,
    required this.questions,
  }) : super(key: key);

  final TestModel testModel;
  final List<int> selection;
  final List<Question> questions;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _current = 0;

  static const Color _primary = Color(0xff3D1975);
  static const Color _correct = Color(0xff4CAF50);
  static const Color _wrong = Color(0xffF44336);

  void _goTo(int index) {
    HapticFeedback.selectionClick();
    setState(() => _current = index);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_current];
    final userAnswer = widget.selection[_current];
    final total = widget.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xffF0EBFF),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          _Header(
            testName: widget.testModel.name,
            current: _current,
            total: total,
            onBack: () => Navigator.pop(context),
          ),

          // ── Progress bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_current + 1) / total,
                backgroundColor: _primary.withOpacity(0.1),
                color: _primary,
                minHeight: 5,
              ),
            ),
          ),

          // ── Scrollable question content ───────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // Question text card
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
                  ),
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                  ),
                ),

                // Image (only if present)
                if (question.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      question.imageUrl,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              height: 80,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: _primary, strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Options
                ...[1, 2, 3, 4].map((opt) => _ResultOption(
                      label: String.fromCharCode(64 + opt),
                      text: question.optionText(opt),
                      isCorrect: question.answer == opt,
                      isSelected: userAnswer == opt,
                    )),

                // Explanation (if present)
                if (question.explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xff3D1975).withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_rounded,
                                color: Colors.amber.shade700, size: 16),
                            const SizedBox(width: 6),
                            const Text('Explanation',
                                style: TextStyle(
                                    color: _primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(question.explanation,
                            style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Prev / Next
                Row(
                  children: [
                    _NavBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Prev',
                      trailing: false,
                      enabled: _current > 0,
                      onTap: () => _goTo(_current - 1),
                    ),
                    const SizedBox(width: 12),
                    _NavBtn(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'Next',
                      trailing: true,
                      enabled: _current < total - 1,
                      onTap: () => _goTo(_current + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Question palette FAB ──────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: () => _showPalette(context),
        icon:
            const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
        label: Text(
          '${_current + 1}/$total',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  void _showPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final bottomPad = MediaQuery.of(context).padding.bottom;
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72),
          decoration: const BoxDecoration(
            color: Color(0xffF6F2FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              const SizedBox(height: 8),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _LegendDot(color: _correct, label: 'Correct'),
                    const SizedBox(width: 16),
                    _LegendDot(color: _wrong, label: 'Wrong'),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.grey.shade300, label: 'Skipped'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                  itemCount: widget.questions.length,
                  itemBuilder: (_, i) {
                    final isCurrent = i == _current;
                    final sel = widget.selection[i];
                    final correct = widget.questions[i].answer;
                    Color bg;
                    Color fg = Colors.white;
                    if (isCurrent) {
                      bg = const Color(0xff3D1975);
                    } else if (sel == -1) {
                      bg = Colors.grey.shade200;
                      fg = Colors.grey.shade600;
                    } else if (sel == correct) {
                      bg = _correct;
                    } else {
                      bg = _wrong;
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _goTo(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                            color: bg, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: bottomPad + 16),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.testName,
    required this.current,
    required this.total,
    required this.onBack,
  });
  final String testName;
  final int current;
  final int total;
  final VoidCallback onBack;

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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Review Answers',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Q ${current + 1} / $total',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option tile ────────────────────────────────────────────────────────────────

class _ResultOption extends StatelessWidget {
  const _ResultOption({
    required this.label,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });
  final String label;
  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color borderColor;
    IconData? trailingIcon;

    if (isCorrect) {
      bg = const Color(0xff4CAF50).withOpacity(0.12);
      fg = const Color(0xff2E7D32);
      borderColor = const Color(0xff4CAF50);
      trailingIcon = Icons.check_circle_rounded;
    } else if (isSelected) {
      bg = const Color(0xffF44336).withOpacity(0.1);
      fg = const Color(0xffC62828);
      borderColor = const Color(0xffF44336);
      trailingIcon = Icons.cancel_rounded;
    } else {
      bg = Colors.white;
      fg = const Color(0xff555555);
      borderColor = Colors.grey.shade200;
      trailingIcon = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xff4CAF50)
                    : isSelected
                        ? const Color(0xffF44336)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: (isCorrect || isSelected)
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon,
                  color: isCorrect
                      ? const Color(0xff4CAF50)
                      : const Color(0xffF44336),
                  size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool trailing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!trailing)
                Icon(icon,
                    size: 14,
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
                    size: 14,
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

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
