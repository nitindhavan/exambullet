import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/dashboard/exam_news_tab.dart';
import 'package:percent/screens/dashboard/focus_tab.dart';
import 'package:percent/screens/dashboard/notes_tab.dart';
import 'package:percent/screens/dashboard/planner_tab.dart';
import 'package:percent/screens/dashboard/quiz_tab.dart';
import 'package:percent/screens/dashboard/tests_tab.dart';
import 'package:percent/services/membership_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';

class EmbeddedDashboard extends StatefulWidget {
  const EmbeddedDashboard({
    Key? key,
    required this.exam,
    required this.user,
  }) : super(key: key);

  final ExamModel exam;
  final UserModel user;

  @override
  State<EmbeddedDashboard> createState() => _EmbeddedDashboardState();
}

class _EmbeddedDashboardState extends State<EmbeddedDashboard> {
  int _currentIndex = 0;
  bool _hasMembership = false;
  bool _membershipLoaded = false;
  StreamSubscription<bool>? _membershipSub;

  List<String> _tabs = ['Tests', 'Updates'];
  bool _tabsLoaded = false;

  @override
  void initState() {
    super.initState();
    _listenToMembership();
    _checkTabsExistence();
  }

  @override
  void didUpdateWidget(covariant EmbeddedDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exam.id != widget.exam.id) {
      _membershipSub?.cancel();
      _membershipLoaded = false;
      _tabsLoaded = false;
      _currentIndex = 0;
      _listenToMembership();
      _checkTabsExistence();
    }
  }

  @override
  void dispose() {
    _membershipSub?.cancel();
    super.dispose();
  }

  void _listenToMembership() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _membershipLoaded = true);
      return;
    }
    // App-wide membership: one active record unlocks every exam.
    _membershipSub = MembershipService.hasAccessStream().listen((hasAccess) {
      if (!mounted) return;
      setState(() {
        _hasMembership = hasAccess;
        _membershipLoaded = true;
      });
    }, onError: (err) {
      debugPrint('Error listening to membership: $err');
      if (mounted) setState(() => _membershipLoaded = true);
    });
  }

  Future<void> _checkTabsExistence() async {
    final List<String> availableTabs = ['Tests'];

    try {
      final notesSnap = await FirebaseDatabase.instance.ref('notes').child(widget.exam.id).once();
      if (notesSnap.snapshot.value != null && (notesSnap.snapshot.value as Map).isNotEmpty) {
        availableTabs.add('Notes');
      }

      final practiceSnap = await FirebaseDatabase.instance.ref('subjects').orderByChild('examId').equalTo(widget.exam.id).once();
      if (practiceSnap.snapshot.value != null && (practiceSnap.snapshot.value as Map).isNotEmpty) {
        availableTabs.add('Practice');
      }
    } catch (e) {
      debugPrint('Error checking tabs: $e');
    }

    // Per-exam study tools — always available (they don't depend on content).
    availableTabs.add('Planner');
    availableTabs.add('Focus');
    availableTabs.add('Updates');

    if (mounted) {
      setState(() {
        _tabs = availableTabs;
        _tabsLoaded = true;
        if (_currentIndex >= _tabs.length) {
          _currentIndex = 0;
        }
      });
    }
  }

  Widget _currentTab() {
    if (!_membershipLoaded || !_tabsLoaded) return const PercentLoaderCentered();
    switch (_tabs[_currentIndex]) {
      case 'Tests':
        return TestsTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Notes':
        return NotesTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Practice':
        return QuizTab(exam: widget.exam, hasMembership: _hasMembership);
      case 'Planner':
        return PlannerTab(singleExam: widget.exam);
      case 'Focus':
        return FocusTab(singleExam: widget.exam);
      case 'Updates':
        return ExamNewsTab(exam: widget.exam);
      default:
        return const SizedBox();
    }
  }

  IconData _iconFor(String tab) {
    switch (tab) {
      case 'Tests':
        return Icons.assignment_rounded;
      case 'Notes':
        return Icons.auto_stories_rounded;
      case 'Practice':
        return Icons.lightbulb_rounded;
      case 'Planner':
        return Icons.checklist_rounded;
      case 'Focus':
        return Icons.timer_rounded;
      case 'Updates':
        return Icons.newspaper_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Content fills the area; the per-exam tabs live in a floating bottom nav
    // that overlays it (matching the home nav style).
    return Stack(
      children: [
        Positioned.fill(
          // Bottom padding so tab content clears the floating tab bar.
          child: Padding(
            padding: const EdgeInsets.only(bottom: 74),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey('${widget.exam.id}_$_currentIndex'),
                child: _currentTab(),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _FloatingTabBar(
            tabs: _tabs,
            currentIndex: _currentIndex,
            iconFor: _iconFor,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ],
    );
  }
}

/// Floating frosted bottom nav for the per-exam dashboard tabs.
class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.iconFor,
    required this.onTap,
  });
  final List<String> tabs;
  final int currentIndex;
  final IconData Function(String) iconFor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad > 0 ? bottomPad : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = i == currentIndex;
                final label = tabs[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconFor(label),
                            size: 21,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
