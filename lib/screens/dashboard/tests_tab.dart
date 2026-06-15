import 'package:percent/models/exam.dart';
import 'package:percent/models/test_model.dart';
import 'package:percent/screens/membership_screen.dart';
import 'package:percent/screens/test_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

class TestsTab extends StatefulWidget {
  const TestsTab({Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> {
  int _selectedTest = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('exams/${widget.exam.id}/tests')
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final raw = snapshot.data!.snapshot.value;
        final tests = raw == null
            ? <TestModel>[]
            : snapshot.data!.snapshot.children
                .map((s) => TestModel.fromMap(s.value as Map))
                .toList();

        if (tests.isNotEmpty) {
          tests.sort((a, b) => _compareNames(a.name, b.name));
        }

        if (tests.isEmpty) {
          return const _EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No tests yet',
            subtitle: 'Mock tests for this exam will appear here.',
          );
        }

        if (_selectedTest >= tests.length) _selectedTest = 0;

        final selected = tests[_selectedTest];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text('Mock Tests',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  _Chip('${tests.length} tests'),
                ],
              ),
            ),

            // ── Segmented test switcher ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: tests.asMap().entries.map((entry) {
                    final i = entry.key;
                    final test = entry.value;
                    final isSelected = _selectedTest == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.hasMembership) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MemberShipScreen(model: widget.exam.id),
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedTest = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary
                                          .withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                test.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!widget.hasMembership && i > 0) ...[
                                const SizedBox(height: 2),
                                Icon(Icons.lock_rounded,
                                    size: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppTheme.warning),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Selected test info ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 13, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text('${selected.time} mins',
                      style:
                          TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),

            // ── Papers for selected test ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.hasMembership
                    ? _PapersList(test: selected, examId: widget.exam.id)
                    : _LockedState(examId: widget.exam.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppTheme.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 36, color: AppTheme.warning),
            ),
            const SizedBox(height: 16),
            const Text('Members Only',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Get membership to access all tests',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MemberShipScreen(model: examId)),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Text('Get Membership',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Papers list ───────────────────────────────────────────────────────────────

class _PapersList extends StatelessWidget {
  const _PapersList({required this.test, required this.examId});
  final TestModel test;
  final String examId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance
          .ref('exams/$examId/tests/${test.id}/papersInfo')
          .once(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2)),
          );
        }

        final papers = snapshot.data!.snapshot.children.toList();

        if (papers.isNotEmpty) {
          papers.sort((a, b) {
            final mapA = a.value as Map?;
            final mapB = b.value as Map?;
            final nameA = mapA?['name'] as String? ?? '';
            final nameB = mapB?['name'] as String? ?? '';
            return _compareNames(nameA, nameB);
          });
        }

        if (papers.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('No papers available',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...papers.asMap().entries.map((entry) {
              final i = entry.key;
              final paperSnap = entry.value;

              final paperMap = paperSnap.value as Map?;
              final paperId = paperMap?['id'] as String? ?? paperSnap.key!;
              final name = paperMap?['name'] as String? ?? 'Paper ${i + 1}';
              final paperTime = (paperMap?['time'] as int?) ?? test.time;
              final easy = (paperMap?['easy'] as int?) ?? 0;
              final medium = (paperMap?['medium'] as int?) ?? 0;
              final hard = (paperMap?['hard'] as int?) ?? 0;
              final questionCount = (paperMap?['questionCount'] as int?) ??
                  (easy + medium + hard);
              final totalMarks = (paperMap?['totalMarks'] as int?) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestScreen(
                        testModel: test,
                        examId: examId,
                        paperId: paperId,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.help_outline_rounded,
                                      size: 12, color: AppTheme.textLight),
                                  const SizedBox(width: 4),
                                  Text('$questionCount Qs',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.timer_outlined,
                                      size: 12, color: AppTheme.textLight),
                                  const SizedBox(width: 4),
                                  Text('$paperTime mins',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.stars_rounded,
                                      size: 12, color: AppTheme.textLight),
                                  const SizedBox(width: 4),
                                  Text('$totalMarks marks',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: AppTheme.primary, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
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
            Icon(icon, size: 52, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

int _compareNames(String a, String b) {
  final regExp = RegExp(r'\d+');
  final matchA = regExp.firstMatch(a);
  final matchB = regExp.firstMatch(b);

  if (matchA != null && matchB != null) {
    final int valA = int.parse(matchA.group(0)!);
    final int valB = int.parse(matchB.group(0)!);
    if (valA != valB) {
      return valA.compareTo(valB);
    }
  }
  return a.compareTo(b);
}
