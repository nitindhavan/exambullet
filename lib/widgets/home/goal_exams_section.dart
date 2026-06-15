import 'package:percent/models/exam.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer.dart';

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
              const Text(
                'My Goals',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 13, color: AppTheme.primary),
                      SizedBox(width: 5),
                      Text(
                        'Manage',
                        style: TextStyle(
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
            height: 200,
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
    return ShimmerLoading(
      builder: (context, color) {
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            itemCount: 3,
            itemBuilder: (_, __) {
              return Container(
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
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 14,
                            width: 48,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
                      child: Image.network(
                        exam.icon,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
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
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
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
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 9,
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
          color: AppTheme.primaryLight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add More',
              textAlign: TextAlign.center,
              style: TextStyle(
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.flag_outlined,
                  color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your exam goals',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pin exams you\'re preparing for and track them here',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
               ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
