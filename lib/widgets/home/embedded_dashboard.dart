import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/dashboard/exam_news_tab.dart';
import 'package:percent/screens/dashboard/notes_tab.dart';
import 'package:percent/screens/dashboard/quiz_tab.dart';
import 'package:percent/screens/dashboard/tests_tab.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer_loading.dart';

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
  StreamSubscription<DatabaseEvent>? _membershipSub;

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
    _membershipSub = FirebaseDatabase.instance
        .ref('memberships')
        .child(widget.exam.id)
        .child(uid)
        .onValue
        .listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.snapshot.exists) {
          final rawData = event.snapshot.value;
          if (rawData is Map) {
            _hasMembership = rawData['isActive'] != false;
          } else {
            _hasMembership = true;
          }
        } else {
          _hasMembership = false;
        }
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
    if (!_membershipLoaded || !_tabsLoaded) return const SkeletonLoader();
    switch (_tabs[_currentIndex]) {
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
    return Column(
      children: [
        // Inner Tab Switcher
        Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.inter(
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Tab Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey('${widget.exam.id}_$_currentIndex'),
              child: _currentTab(),
            ),
          ),
        ),
      ],
    );
  }
}
