import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/services/problem_report_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Reason choices shown per report type. Kept short so admin can triage by
/// filtering on `reason`.
const _kReasonsByType = {
  'question': [
    'Wrong answer',
    'Wrong question',
    'Typo / formatting',
    'Bad or missing options',
    'Wrong explanation',
    'Other',
  ],
  'paper': [
    'Repeated questions',
    'Wrong total marks',
    'Too few / too many questions',
    'Off-syllabus questions',
    'Other',
  ],
  'test': [
    'Wrong duration',
    'Wrong marks / negative marking',
    'Wrong test details',
    'Other',
  ],
};

const _kTitleByType = {
  'question': 'Report this question',
  'paper': 'Report this paper',
  'test': 'Report this test',
};

/// Opens the report bottom sheet. [type] is one of 'question' | 'paper' |
/// 'test'; pass whichever ids are relevant for that type. Shows a success
/// SnackBar on submit. Mirrors [showSignInSheet].
Future<void> showReportSheet(
  BuildContext context, {
  required String type,
  required String examId,
  String testId = '',
  String paperId = '',
  String questionId = '',
  String questionText = '',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(
      type: type,
      examId: examId,
      testId: testId,
      paperId: paperId,
      questionId: questionId,
      questionText: questionText,
    ),
  );
}

/// Small "report a problem" affordance: an outlined flag pill. Use inside a
/// question/paper/test card and wire [onTap] to [showReportSheet].
class ReportButton extends StatelessWidget {
  const ReportButton({Key? key, required this.onTap, this.compact = false})
      : super(key: key);
  final VoidCallback onTap;

  /// When true, shows just the flag icon (no "Report" label) — for tight rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined,
                size: 15, color: AppTheme.textSecondary),
            if (!compact) ...[
              const SizedBox(width: 5),
              Text(
                'Report',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.type,
    required this.examId,
    required this.testId,
    required this.paperId,
    required this.questionId,
    required this.questionText,
  });

  final String type;
  final String examId;
  final String testId;
  final String paperId;
  final String questionId;
  final String questionText;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _noteController = TextEditingController();
  String? _reason;
  bool _submitting = false;

  List<String> get _reasons =>
      _kReasonsByType[widget.type] ?? const ['Other'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _submitting = true);
    final report = await ProblemReportService.submit(
      type: widget.type,
      reason: _reason!,
      note: _noteController.text.trim(),
      examId: widget.examId,
      testId: widget.testId,
      paperId: widget.paperId,
      questionId: widget.questionId,
      questionText: widget.questionText,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(report != null
            ? 'Thanks — your report has been submitted.'
            : 'Could not submit report. Please try again.'),
        backgroundColor: report != null ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _kTitleByType[widget.type] ?? 'Report a problem';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: AppTheme.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.questionText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  widget.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'What’s wrong?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final selected = _reason == r;
                return GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppTheme.primary : AppTheme.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.borderLight,
                      ),
                    ),
                    child: Text(
                      r,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Add a note (optional)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Describe the problem…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppTheme.textLight),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Submit report',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _reason == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
