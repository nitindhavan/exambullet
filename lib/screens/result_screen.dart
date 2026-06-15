import 'package:percent/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';
import 'package:percent/utils/theme.dart';

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

  static const Color _primary = AppTheme.primary;
  static const Color _correct = AppTheme.success;
  static const Color _wrong = AppTheme.error;

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
      backgroundColor: AppTheme.background,
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
                backgroundColor: AppTheme.primaryLight,
                color: AppTheme.primary,
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
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
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
                          color: AppTheme.borderLight),
                      boxShadow: AppTheme.softShadow,
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
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(question.explanation,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
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
            color: AppTheme.background,
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
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              // Legend
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _LegendDot(color: _correct, label: 'Correct'),
                    SizedBox(width: 16),
                    _LegendDot(color: _wrong, label: 'Wrong'),
                    SizedBox(width: 16),
                    _LegendDot(color: AppTheme.border, label: 'Skipped'),
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
                      bg = AppTheme.primary;
                    } else if (sel == -1) {
                      bg = AppTheme.borderLight;
                      fg = AppTheme.textSecondary;
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
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isCurrent ? AppTheme.primary : AppTheme.borderLight,
                                width: 1.5),
                            boxShadow: AppTheme.softShadow),
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
          colors: AppTheme.primaryGradient,
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
                        color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
      bg = AppTheme.successLight;
      fg = const Color(0xff065F46);
      borderColor = AppTheme.success;
      trailingIcon = Icons.check_circle_rounded;
    } else if (isSelected) {
      bg = AppTheme.errorLight;
      fg = const Color(0xff991B1B);
      borderColor = AppTheme.error;
      trailingIcon = Icons.cancel_rounded;
    } else {
      bg = Colors.white;
      fg = AppTheme.textPrimary;
      borderColor = AppTheme.borderLight;
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
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppTheme.success
                    : isSelected
                        ? AppTheme.error
                        : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: (isCorrect || isSelected)
                            ? Colors.white
                            : AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: fg, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon,
                  color: isCorrect
                      ? AppTheme.success
                      : AppTheme.error,
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
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: enabled ? AppTheme.softShadow : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!trailing)
                Icon(icon,
                    size: 14,
                    color: enabled
                        ? AppTheme.primary
                        : Colors.grey.shade300),
              if (!trailing) const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: enabled
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (trailing) const SizedBox(width: 6),
              if (trailing)
                Icon(icon,
                    size: 14,
                    color: enabled
                        ? AppTheme.primary
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
