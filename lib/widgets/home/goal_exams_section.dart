import 'package:percent/models/exam.dart';
import 'package:flutter/material.dart';

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
                  color: Color(0xff2D0F5E),
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
                    color: const Color(0xff3D1975).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 13, color: Color(0xff3D1975)),
                      SizedBox(width: 5),
                      Text(
                        'Manage',
                        style: TextStyle(
                          color: Color(0xff3D1975),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xff3D1975))),
          )
        else if (goalExams.isEmpty)
          _EmptyGoalsCTA(onTap: onManageTap)
        else
          SizedBox(
            height: 170,
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
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3D1975).withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Circular icon ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xff3D1975).withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                        color: const Color(0xff3D1975).withOpacity(0.12),
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
                        color: Color(0xff3D1975),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Name + active badge ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    exam.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff2D0F5E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Color(0xff4CAF50), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                            color: Color(0xff4CAF50),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
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
        width: 100,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xff3D1975).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xff3D1975).withOpacity(0.18),
              style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: Color(0xff3D1975), size: 32),
            SizedBox(height: 8),
            Text(
              'Add\nMore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff3D1975),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
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
          gradient: LinearGradient(
            colors: [
              const Color(0xff3D1975).withOpacity(0.05),
              const Color(0xff6B3FA0).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff3D1975).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xff3D1975).withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.flag_outlined,
                  color: Color(0xff3D1975), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your exam goals',
                    style: TextStyle(
                      color: Color(0xff2D0F5E),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pin exams you\'re preparing for and track them here',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xff3D1975)),
          ],
        ),
      ),
    );
  }
}
