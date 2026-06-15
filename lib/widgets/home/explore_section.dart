import 'package:percent/models/exam.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({
    Key? key,
    required this.otherExams,
    required this.examsLoading,
    required this.goalIds,
    required this.onViewAllTap,
    required this.onExamTap,
  }) : super(key: key);

  final List<ExamModel> otherExams;
  final bool examsLoading;
  final Set<String> goalIds;
  final VoidCallback onViewAllTap;
  final void Function(ExamModel) onExamTap;

  @override
  Widget build(BuildContext context) {
    final preview = otherExams.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Exams',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (otherExams.length > 4)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (examsLoading)
          _buildShimmer(context)
        else if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              otherExams.isEmpty
                  ? 'No exams available'
                  : 'All exams are in your goals!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: preview.length,
            itemBuilder: (_, i) => _ExploreCard(
                exam: preview[i], onTap: () => onExamTap(preview[i])),
          ),
        if (otherExams.length > 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: GestureDetector(
              onTap: onViewAllTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'View All ${otherExams.length} Exams →',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return ShimmerLoading(
      builder: (context, color) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (_, __) {
            return Container(
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
                        color: AppTheme.borderLight.withValues(alpha: 0.5),
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
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
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
                          height: 20,
                          width: 70,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.exam, required this.onTap});
  final ExamModel exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  color: AppTheme.borderLight.withValues(alpha: 0.5),
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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

            // ── Name + pill ────────────────────────
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Practice',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.primary,
                          size: 10,
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
