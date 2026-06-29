import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/all_exams_screen.dart';
import 'package:percent/screens/exam_dashboard.dart';
import 'package:percent/widgets/home/embedded_dashboard.dart';
import 'package:percent/widgets/home/home_header.dart';
import 'package:percent/widgets/home/news_section.dart';
import 'package:percent/screens/privacy_policy_screen.dart';
import 'package:percent/screens/edit_profile_screen.dart';
import 'package:percent/widgets/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.user}) : super(key: key);
  final UserModel user;

  @override
  State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  List<ExamModel> allExams = [];
  bool examsLoading = true;
  late final Stream<Set<String>> _goalIdsStream;
  int _activeTab = 0;
  String _exploreSearchQuery = '';
  String? _selectedRoomsExamId;
  final TextEditingController _exploreSearchController = TextEditingController();

  @override
  void dispose() {
    _exploreSearchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _goalIdsStream = FirebaseDatabase.instance
        .ref('users/$uid/goalExamIds')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <String>{};
      return (event.snapshot.value as Map).keys.cast<String>().toSet();
    });
    _loadExams();
  }

  Future<void> _loadExams() async {
    final snap = await FirebaseDatabase.instance.ref('exams').once();
    if (!mounted) return;
    if (snap.snapshot.value == null) {
      setState(() => examsLoading = false);
      return;
    }
    final raw = snap.snapshot.value as Map;
    setState(() {
      allExams = raw.entries
          .map((e) => ExamModel.fromMap(e.value as Map, e.key as String))
          .where((e) => e.visible)
          .toList();
      examsLoading = false;
    });
  }

  void _openAllExams(Set<String> goalIds) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => AllExamsScreen(allExams: allExams, goalIds: goalIds)));
  }

  void _openExamDashboard(ExamModel exam) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => ExamDashboard(exam: exam, user: widget.user)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<Set<String>>(
      stream: _goalIdsStream,
      initialData: const {},
      builder: (context, snap) {
        final goalIds   = snap.data ?? {};
        final goalExams = allExams.where((e) => goalIds.contains(e.id)).toList();
        final otherExams = allExams.where((e) => !goalIds.contains(e.id)).toList();

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: _DesktopHome(
              user: widget.user,
              goalExams: goalExams,
              otherExams: otherExams,
              examsLoading: examsLoading,
              goalIds: goalIds,
              onManageTap: () => _openAllExams(goalIds),
              onExamTap: _openExamDashboard,
            ),
          );
        }


        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: _buildTabBody(
              goalExams: goalExams,
              otherExams: otherExams,
              goalIds: goalIds,
              examsLoading: examsLoading,
            ),
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: _activeTab,
            onTap: (index) => setState(() => _activeTab = index),
            hasGoals: goalExams.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _buildTabBody({
    required List<ExamModel> goalExams,
    required List<ExamModel> otherExams,
    required Set<String> goalIds,
    required bool examsLoading,
  }) {
    switch (_activeTab) {
      case 0:
        return _buildRoomsTab(goalExams, goalIds, examsLoading);
      case 1:
        return _buildExploreTab(allExams, goalIds, examsLoading);
      case 2:
        return _ProfileTab(
          user: widget.user,
          goalExams: goalExams,
          allExams: allExams,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildRoomsTab(List<ExamModel> goalExams, Set<String> goalIds, bool examsLoading) {
    if (goalExams.isNotEmpty) {
      final containsSelected = goalExams.any((e) => e.id == _selectedRoomsExamId);
      if (!containsSelected) _selectedRoomsExamId = goalExams.first.id;
    } else {
      _selectedRoomsExamId = null;
    }

    // Header + section title (scrolls away)
    Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeHeader(
          user: widget.user,
          goalCount: goalExams.length,
          onTapSearch: () => setState(() => _activeTab = 1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Prep Rooms',
                  style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              if (goalExams.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Text('Manage',
                      style: GoogleFonts.inter(
                          color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ],
    );

    if (examsLoading) {
      return Column(
        children: [
          header,
          Expanded(
            child: ShimmerLoading(
              builder: (context, color) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        4,
                        (_) => Container(
                          width: 72, height: 72,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (_, __) => Container(
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (goalExams.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text('No Prep Rooms Active',
                        style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Select the exams you are preparing for in the Explore tab to customize your mock tests and start learning.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() => _activeTab = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Explore Exams',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Has goals: use NestedScrollView so header + exam switcher scroll,
    // then the inner tab bar sticks and EmbeddedDashboard fills the rest.
    final selectedExam = goalExams.firstWhere((e) => e.id == _selectedRoomsExamId);
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(child: header),
        // Horizontal exam switcher scrolls with the header
        SliverToBoxAdapter(
          child: SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: goalExams.length,
              itemBuilder: (context, index) {
                final exam = goalExams[index];
                final isSelected = exam.id == _selectedRoomsExamId;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRoomsExamId = exam.id),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: AppTheme.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey.shade200,
                            ),
                            child: Container(
                              width: 48, height: 48,
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    exam.icon,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exam.name,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      body: EmbeddedDashboard(
        key: ValueKey(selectedExam.id),
        exam: selectedExam,
        user: widget.user,
      ),
    );
  }

  Widget _buildExploreTab(List<ExamModel> allExams, Set<String> goalIds, bool examsLoading) {
    final filteredExams = allExams.where((e) {
      final query = _exploreSearchQuery.toLowerCase();
      return e.name.toLowerCase().contains(query);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Explore Exams',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
        // Search Input Bar
        SliverToBoxAdapter(
          child: Container(
            height: 46,
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary.withValues(alpha: 0.65),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _exploreSearchController,
                    onChanged: (val) {
                      setState(() {
                        _exploreSearchQuery = val;
                      });
                    },
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for exams...',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textSecondary.withValues(alpha: 0.55),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_exploreSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _exploreSearchController.clear();
                      setState(() {
                        _exploreSearchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.65),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (examsLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (filteredExams.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.35),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Exams Found',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try searching for other keywords.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exam = filteredExams[index];
                  final isGoal = goalIds.contains(exam.id);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isGoal ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isGoal ? AppTheme.primaryLight : Colors.grey.shade50,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isGoal ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      exam.icon,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.school_rounded,
                                        color: isGoal ? AppTheme.primary : AppTheme.textSecondary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  exam.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            final ref = FirebaseDatabase.instance.ref('users/$uid/goalExamIds');
                            if (isGoal) {
                              await ref.child(exam.id).remove();
                            } else {
                              await ref.child(exam.id).set(true);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isGoal ? AppTheme.primaryLight : AppTheme.primary,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isGoal ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                                  color: isGoal ? AppTheme.primary : Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isGoal ? 'Added' : 'Add Goal',
                                  style: GoogleFonts.inter(
                                    color: isGoal ? AppTheme.primary : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: filteredExams.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.hasGoals,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasGoals;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final items = [
      const _NavItem(Icons.home_rounded, 'My Rooms'),
      const _NavItem(Icons.explore_rounded, 'Explore'),
      const _NavItem(Icons.person_rounded, 'Profile'),
    ];

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
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 10),
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
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primary : AppTheme.textSecondary,
                        ),
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

// ── Desktop two-column home ───────────────────────────────────────────────────

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({
    required this.user,
    required this.goalExams,
    required this.otherExams,
    required this.examsLoading,
    required this.goalIds,
    required this.onManageTap,
    required this.onExamTap,
  });

  final UserModel user;
  final List<ExamModel> goalExams;
  final List<ExamModel> otherExams;
  final bool examsLoading;
  final Set<String> goalIds;
  final VoidCallback onManageTap;
  final void Function(ExamModel) onExamTap;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left sidebar ──────────────────────────────────────────────────────
        Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppTheme.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: SafeArea(
            right: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name
                  _DesktopAvatar(user: user),
                  const SizedBox(height: 24),
                  // Stat tiles
                  _DesktopStatTile(
                    icon: Icons.flag_rounded,
                    value: '${goalExams.length} Active',
                    label: 'Goal Exams',
                  ),
                  const SizedBox(height: 10),
                  _DesktopStatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: 'Daily',
                    label: 'Practice Streak',
                  ),
                  const SizedBox(height: 20),
                  // Integrated Search Bar
                  GestureDetector(
                    onTap: onManageTap,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.65),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search exams...',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Goal exams list in sidebar
                  Text('My Goals',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  if (examsLoading)
                    ...List.generate(3, (_) => _GoalShimmerTile())
                  else if (goalExams.isEmpty)
                    _EmptySidebarGoal(onTap: onManageTap)
                  else ...[
                    ...goalExams.map((e) => _SidebarExamTile(
                          exam: e,
                          onTap: () => onExamTap(e),
                        )),
                    const SizedBox(height: 4),
                    _SidebarManageBtn(onTap: onManageTap),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad + 24)),

              // Section: Explore Exams (full-width grid, more columns)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Explore Exams',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (otherExams.length > 6)
                        TextButton(
                          onPressed: onManageTap,
                          child: const Text('View All',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                sliver: _DesktopExamGrid(
                  exams: otherExams,
                  examsLoading: examsLoading,
                  onExamTap: onExamTap,
                ),
              ),

              // Section: News
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: NewsSection(goalExams: goalExams),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Desktop sidebar widgets ───────────────────────────────────────────────────

class _DesktopAvatar extends StatelessWidget {
  const _DesktopAvatar({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim();
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      initials = parts.first.substring(0, 1);
      if (parts.length > 1 && parts.last.isNotEmpty) {
        initials += parts.last.substring(0, 1);
      }
    }
    return Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Center(
          child: initials.isNotEmpty
              ? Text(initials.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))
              : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hey, ${name.split(' ').first} 👋',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Ready to boost your percent?',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
        ]),
      ),
    ]);
  }
}

class _DesktopStatTile extends StatelessWidget {
  const _DesktopStatTile(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _SidebarExamTile extends StatelessWidget {
  const _SidebarExamTile({required this.exam, required this.onTap});
  final ExamModel exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          ClipOval(
            child: Image.network(exam.icon,
                width: 32, height: 32, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 16),
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(exam.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 16),
        ]),
      ),
    );
  }
}

class _SidebarManageBtn extends StatelessWidget {
  const _SidebarManageBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Center(
          child: Text('Manage Goals',
              style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _EmptySidebarGoal extends StatelessWidget {
  const _EmptySidebarGoal({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Column(children: [
          Icon(Icons.flag_outlined, color: Colors.white.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text('No goals set',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap to add exams',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
      ),
    );
  }
}

class _GoalShimmerTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Desktop exam grid sliver ──────────────────────────────────────────────────

class _DesktopExamGrid extends StatelessWidget {
  const _DesktopExamGrid({
    required this.exams,
    required this.examsLoading,
    required this.onExamTap,
  });
  final List<ExamModel> exams;
  final bool examsLoading;
  final void Function(ExamModel) onExamTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 280; // subtract sidebar
    final crossCount = width > 900 ? 4 : 3;

    if (examsLoading) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
          ),
          childCount: crossCount * 2,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          childAspectRatio: 0.85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
      );
    }

    if (exams.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('All exams are in your goals!',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _DesktopExamCard(exam: exams[i], onTap: () => onExamTap(exams[i])),
        childCount: exams.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
    );
  }
}

class _DesktopExamCard extends StatelessWidget {
  const _DesktopExamCard({required this.exam, required this.onTap});
  final ExamModel exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(exam.icon,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.school_rounded,
                              color: AppTheme.primary, size: 28)),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(exam.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Open',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isDestructive ? Colors.redAccent : AppTheme.primary,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    Key? key,
    required this.user,
    required this.goalExams,
    required this.allExams,
  }) : super(key: key);

  final UserModel user;
  final List<ExamModel> goalExams;
  final List<ExamModel> allExams;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  List<String> _memberships = [];
  Map<String, String> _membershipDates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMemberships();
  }

  Future<void> _fetchMemberships() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final active = <String>[];
    final dates = <String, String>{};
    for (final exam in widget.goalExams) {
      try {
        final snap = await FirebaseDatabase.instance.ref('memberships/${exam.id}/$uid').once();
        if (snap.snapshot.exists) {
          final raw = snap.snapshot.value;
          if (raw is Map && raw['isActive'] != false) {
            active.add(exam.id);
            if (raw['membershipDate'] != null) {
              dates[exam.id] = raw['membershipDate'].toString();
            }
          } else if (raw != null && raw is! Map) {
            active.add(exam.id);
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _memberships = active;
        _membershipDates = dates;
        _loading = false;
      });
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'My Profile',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name
                            : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Membership Dashboard Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Membership Details',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  ShimmerLoading(
                    builder: (context, color) => Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShimmerLoading(
                    builder: (context, color) => Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_memberships.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_border_rounded,
                        color: AppTheme.textSecondary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free Plan',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upgrade inside prep rooms to unlock premium mock tests & features.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.allExams
                .where((e) => _memberships.contains(e.id))
                .map((exam) {
              final dateStr = _membershipDates[exam.id];
              return Container(
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: icon + exam name + active badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                exam.icon,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school_rounded,
                                    color: AppTheme.primary,
                                    size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exam.name,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    // Bottom row: plan type + joined date
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: AppTheme.primary, size: 15),
                          const SizedBox(width: 6),
                          const Text(
                            'Premium Plan',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (dateStr != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: AppTheme.border,
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_outlined,
                                color: AppTheme.textSecondary, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              'Since ${_formatDate(dateStr)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 32),

          // Options
          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: widget.user),
                ),
              );
              if (updated == true && mounted) {
                setState(() {});
              }
            },
          ),
          _ProfileOption(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          const SizedBox(height: 20),
          _ProfileOption(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            isDestructive: true,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
