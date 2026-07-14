import 'package:percent/models/exam.dart';
import 'package:percent/models/test_model.dart';
import 'package:percent/screens/membership_screen.dart';
import 'package:percent/screens/test_screen.dart';
import 'package:percent/services/guest_gate.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer.dart';

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
          .ref('tests')
          .orderByChild('examId')
          .equalTo(widget.exam.id)
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ShimmerLoading(
            builder: (context, color) {
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          );
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

        return CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text('Mock Tests', style: AppTheme.headingMd),
                    const Spacer(),
                    _Chip('${tests.length} tests'),
                  ],
                ),
              ),
            ),

            // ── Test selector chip rail (distinct from the outer
            //    Tests/Updates pill switcher so they don't look duplicated) ──
            if (tests.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    itemCount: tests.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final test = tests[i];
                      final isSelected = _selectedTest == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTest = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            test.name,
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
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(top: 12)),

            // ── Papers for selected test ─────────────────────────
            _PapersSliver(
              test: selected,
              examId: widget.exam.id,
              hasMembership: widget.hasMembership,
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        );
      },
    );
  }
}

// ── Papers list ───────────────────────────────────────────────────────────────

class _PapersSliver extends StatelessWidget {
  const _PapersSliver({required this.test, required this.examId, required this.hasMembership});
  final TestModel test;
  final String examId;
  final bool hasMembership;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance
          .ref('papersInfo')
          .orderByChild('testId')
          .equalTo(test.id)
          .once(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
            ),
          );
        }

        final papers = snapshot.data!.snapshot.children.toList();

        if (papers.isNotEmpty) {
          papers.sort((a, b) {
            final nameA = (a.value as Map?)?['name'] as String? ?? '';
            final nameB = (b.value as Map?)?['name'] as String? ?? '';
            return _compareNames(nameA, nameB);
          });
        }

        if (papers.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text('No papers available',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final paperSnap = papers[i];
                final paperMap = paperSnap.value as Map?;
                final paperId = paperMap?['id'] as String? ?? paperSnap.key!;
                final name = paperMap?['name'] as String? ?? 'Paper ${i + 1}';
                final paperTime = (paperMap?['time'] as int?) ?? test.time;
                final easy = (paperMap?['easy'] as int?) ?? 0;
                final medium = (paperMap?['medium'] as int?) ?? 0;
                final hard = (paperMap?['hard'] as int?) ?? 0;
                final questionCount =
                    (paperMap?['questionCount'] as int?) ?? (easy + medium + hard);
                final totalMarks = (paperMap?['totalMarks'] as int?) ?? 0;
                // Guests (anonymous web visitors) may take tests — we only nudge
                // them to sign in so their results are saved. Membership locking
                // (first test free, rest need membership) applies to everyone.
                final isGuest = GuestGate.isGuest;
                final isLocked = !hasMembership && i > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      if (isLocked) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MemberShipScreen(model: examId),
                        ));
                        return;
                      }
                      // Non-blocking: let the test open, but nudge a guest to
                      // sign in so their attempt/results aren't lost.
                      if (isGuest) {
                        GuestGate.softNudge(context, reason: 'test results');
                      }
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TestScreen(
                          testModel: test,
                          examId: examId,
                          paperId: paperId,
                        ),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLocked ? AppTheme.borderLight : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: isLocked ? [] : AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: isLocked
                                  ? null
                                  : const LinearGradient(
                                      colors: AppTheme.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: isLocked ? AppTheme.border : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isLocked
                                  ? const Icon(Icons.lock_rounded,
                                      color: AppTheme.textSecondary, size: 18)
                                  : Text('${i + 1}',
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: isLocked
                                            ? AppTheme.textSecondary
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    _MetaInfo(
                                        icon: Icons.help_outline_rounded,
                                        label: '$questionCount Qs'),
                                    _MetaInfo(
                                        icon: Icons.timer_outlined,
                                        label: '$paperTime mins'),
                                    _MetaInfo(
                                        icon: Icons.stars_rounded,
                                        label: '$totalMarks marks'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? AppTheme.border
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isLocked
                                  ? Icons.lock_rounded
                                  : Icons.play_arrow_rounded,
                              color: isLocked
                                  ? AppTheme.textSecondary
                                  : AppTheme.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: papers.length,
            ),
          ),
        );
      },
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
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
