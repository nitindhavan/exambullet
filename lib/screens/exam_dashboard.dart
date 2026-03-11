import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/dashboard/exam_news_tab.dart';
import 'package:percent/screens/dashboard/notes_tab.dart';
import 'package:percent/screens/dashboard/quiz_tab.dart';
import 'package:percent/screens/dashboard/tests_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ExamDashboard extends StatefulWidget {
  const ExamDashboard({Key? key, required this.exam, required this.user})
      : super(key: key);
  final ExamModel exam;
  final UserModel user;

  @override
  State<ExamDashboard> createState() => _ExamDashboardState();
}

class _ExamDashboardState extends State<ExamDashboard> {
  int _currentIndex = 0;
  bool _hasMembership = false;
  bool _membershipLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final snap = await FirebaseDatabase.instance
        .ref('memberships')
        .child(widget.exam.id)
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once();
    if (!mounted) return;
    setState(() {
      _hasMembership = snap.snapshot.exists;
      _membershipLoaded = true;
    });
  }

  List<_NavItem> get _navItems {
    return [
      const _NavItem(Icons.assignment_rounded, 'Tests'),
      if (widget.exam.enableNotes)
        const _NavItem(Icons.auto_stories_rounded, 'Notes'),
      if (widget.exam.enableQuiz)
        const _NavItem(Icons.lightbulb_rounded, 'Practice'),
      const _NavItem(Icons.newspaper_rounded, 'Updates'),
    ];
  }

  Widget _currentTab() {
    if (!_membershipLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xff3D1975)));
    }
    final label = _navItems[_currentIndex].label;
    switch (label) {
      case 'Tests':
        return TestsTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Notes':
        return NotesTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Practice':
        return QuizTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Updates':
        return ExamNewsTab(exam: widget.exam);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      body: Column(
        children: [
          _DashboardHeader(
            exam: widget.exam,
            hasMembership: _hasMembership,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _currentTab(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.exam,
    required this.hasMembership,
    required this.onBack,
  });
  final ExamModel exam;
  final bool hasMembership;
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: 0,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: back + pro badge
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    if (hasMembership)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xffFFD700).withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: Color(0xffFFD700), size: 14),
                            SizedBox(width: 5),
                            Text('PRO',
                                style: TextStyle(
                                    color: Color(0xffFFD700),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row: icon + text
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Exam icon with border ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            exam.icon,
                            height: 54,
                            width: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 54,
                              width: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              exam.about,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  height: 1.4),
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
        ],
      ),
    );
  }
}

// ── Custom Pill Bottom Nav ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1E0845).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xff3D1975) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          key: ValueKey(selected),
                          size: 22,
                          color: selected ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : Colors.grey.shade400,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
