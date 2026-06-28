import 'dart:async';
import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/dashboard/exam_news_tab.dart';
import 'package:percent/screens/dashboard/notes_tab.dart';
import 'package:percent/screens/dashboard/quiz_tab.dart';
import 'package:percent/screens/dashboard/tests_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/shimmer_loading.dart';

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
  StreamSubscription<DatabaseEvent>? _membershipSub;

  @override
  void initState() {
    super.initState();
    _listenToMembership();
  }

  @override
  void dispose() {
    _membershipSub?.cancel();
    super.dispose();
  }

  void _listenToMembership() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
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

  List<_NavItem> get _navItems => [
        const _NavItem(Icons.assignment_rounded, 'Tests'),
        const _NavItem(Icons.auto_stories_rounded, 'Notes'),
        const _NavItem(Icons.lightbulb_rounded, 'Practice'),
        const _NavItem(Icons.newspaper_rounded, 'Updates'),
      ];

  Widget _currentTab() {
    if (!_membershipLoaded) return const SkeletonLoader();
    switch (_navItems[_currentIndex].label) {
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ── Desktop: side-rail layout ───────────────────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Left rail
          _DesktopRail(
            exam: widget.exam,
            hasMembership: _hasMembership,
            items: _navItems,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            onBack: () => Navigator.pop(context),
          ),
          // Content area
          Expanded(
            child: Column(
              children: [
                // Compact top bar on desktop
                _DesktopTopBar(
                  exam: widget.exam,
                  hasMembership: _hasMembership,
                  tabLabel: _navItems[_currentIndex].label,
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
          ),
        ],
      ),
    );
  }

  // ── Mobile: original layout ─────────────────────────────────────────────────

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: AppTheme.background,
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

// ── Desktop side rail ─────────────────────────────────────────────────────────

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.exam,
    required this.hasMembership,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onBack,
  });
  final ExamModel exam;
  final bool hasMembership;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header section
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      exam.icon,
                      height: 44, width: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 44, width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  exam.name,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                if (hasMembership) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: Color(0xffFFD700), size: 12),
                        SizedBox(width: 4),
                        Text('PRO',
                            style: TextStyle(
                                color: Color(0xffFFD700),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Nav items
          ...items.asMap().entries.map((e) {
            final selected = e.key == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(e.value.icon,
                        size: 20,
                        color: selected ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Desktop compact top bar ───────────────────────────────────────────────────

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.exam,
    required this.hasMembership,
    required this.tabLabel,
    required this.onBack,
  });
  final ExamModel exam;
  final bool hasMembership;
  final String tabLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            tabLabel,
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary, letterSpacing: -0.5),
          ),
          const Spacer(),
          Text(
            exam.name,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Mobile header ─────────────────────────────────────────────────────────────

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
          colors: AppTheme.primaryGradient,
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
          Positioned(
            right: -20, top: 0,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: -30, bottom: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xffFFD700).withValues(alpha: 0.5)),
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
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            exam.icon,
                            height: 54, width: 54, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 54, width: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
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
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w900, letterSpacing: -0.4, height: 1.1),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              exam.about,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12, height: 1.4),
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

// ── Mobile bottom nav ─────────────────────────────────────────────────────────

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
            color: Colors.black.withValues(alpha: 0.04),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(item.icon,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected ? AppTheme.primary : AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primary : AppTheme.textSecondary,
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
