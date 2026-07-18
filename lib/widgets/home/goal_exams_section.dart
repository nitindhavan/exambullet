import 'package:percent/models/exam.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/percent_loader.dart';

class GoalExamsSection extends StatelessWidget {
  const GoalExamsSection({
    Key? key,
    required this.goalExams,
    required this.examsLoading,
    required this.goalIds,
    required this.onManageTap,
    required this.onExamTap,
  }) : super(key: key);

  final List<ExamModel> goalExams;
  final bool examsLoading;
  final Set<String> goalIds;
  final VoidCallback onManageTap;
  final void Function(ExamModel) onExamTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Goals',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: onManageTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 13, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Manage',
                        style: GoogleFonts.inter(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (examsLoading)
          _buildShimmer(context)
        else if (goalExams.isEmpty)
          _EmptyGoalsCTA(onTap: onManageTap)
        else
          SizedBox(
            height: 205,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemCount: goalExams.length + 1,
              itemBuilder: (_, i) {
                if (i == goalExams.length) {
                  return _AddMoreCard(onTap: onManageTap);
                }
                return _GoalExamCard(
                    exam: goalExams[i], onTap: () => onExamTap(goalExams[i]));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: PercentLoaderCentered(),
    );
  }
}

class _GoalExamCard extends StatelessWidget {
  const _GoalExamCard({required this.exam, required this.onTap});
  final ExamModel exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon Area ──────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: ExamIcon(
                        iconKey: exam.iconKey,
                        imageUrl: exam.icon,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Name + active badge ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: Text(
                        exam.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.inter(
                            color: AppTheme.success,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMoreCard extends StatelessWidget {
  const _AddMoreCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 20, bottom: 8, top: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Goal',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoalsCTA extends StatelessWidget {
  const _EmptyGoalsCTA({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_outlined,
                  color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'No active study goals yet',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose and pin exams you are preparing for to track your tests, mock practices, and news updates here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppTheme.primaryGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Configure Goals',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
