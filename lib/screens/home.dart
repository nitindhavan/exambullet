import 'dart:ui' show ImageFilter;
import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/all_exams_screen.dart';
import 'package:percent/screens/analytics_screen.dart';
import 'package:percent/screens/exam_dashboard.dart';
import 'package:percent/widgets/home/embedded_dashboard.dart';
import 'package:percent/widgets/home/home_header.dart';
import 'package:percent/widgets/home/news_section.dart';
import 'package:percent/screens/memberships_screen.dart';
import 'package:percent/screens/privacy_policy_screen.dart';
import 'package:percent/screens/terms_conditions_screen.dart';
import 'package:percent/screens/signin.dart';
import 'package:percent/widgets/sign_in_sheet.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/get_app_banner.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/services/guest_gate.dart';
import 'package:percent/screens/edit_profile_screen.dart';
import 'package:percent/widgets/ui/ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/utils/category_icons.dart';
import 'package:percent/utils/category_theme.dart';

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

  // "Tests" tab drill-in: null = showing category sections; otherwise the
  // selected category id, inside which we show that category's exam grid.
  String? _testsCategoryId;
  // Once an exam is picked inside a category room, its embedded dashboard
  // replaces the grid (no switcher rail — back returns to the grid).
  ExamModel? _testsSelectedExam;
  final TextEditingController _categorySearchCtrl = TextEditingController();
  String _categorySearch = '';
  // Categories loaded from the `categories` node (id, label, order, icon).
  List<_HomeCategory> _categories = [];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _goalIdsStream = uid == null
        ? Stream.value(<String>{})
        : FirebaseDatabase.instance
            .ref('users/$uid/goalExamIds')
            .onValue
            .map((event) {
            if (event.snapshot.value == null) return <String>{};
            return (event.snapshot.value as Map).keys.cast<String>().toSet();
          });
    _loadExams();
    _loadCategories();
    // If a guest just converted to a real account but their name is still the
    // "Guest" placeholder, ask them once what to call them. No-op otherwise.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GuestGate.promptForNameIfNeeded(context);
    });
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('categories').once();
      final cats = <_HomeCategory>[];
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        (snap.snapshot.value as Map).forEach((key, v) {
          if (v is! Map) return;
          cats.add(_HomeCategory(
            key.toString(),
            (v['label'] ?? key).toString(),
            (v['order'] as num?)?.toInt() ?? 999,
            (v['icon'] ?? '').toString(),
          ));
        });
      }
      cats.sort((a, b) => a.order.compareTo(b.order));
      if (mounted) {
        setState(() {
          _categories = cats;
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  @override
  void dispose() {
    _categorySearchCtrl.dispose();
    super.dispose();
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
            builder: (_) => AllExamsScreen(
                allExams: allExams, goalIds: goalIds, user: widget.user)));
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


        // Inside a section (drilled into a category on the Tests tab), hide the
        // app header so the category's own back-arrow + content take full height.
        final insideSection = _activeTab == 0 && _testsCategoryId != null;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: insideSection
              ? null
              : AppTopBar(
                  title: 'Percent',
                  showBack: false,
                  leadingIcon: Icons.percent_rounded,
                  actions: [
                    NotificationBell(userId: widget.user.uid),
                    const SizedBox(width: AppTheme.space5),
                  ],
                ),
          // Body fills the full height; the floating nav overlays it at the
          // bottom so content shows THROUGH the translucent pill (true floating,
          // no solid bar behind it).
          body: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  top: insideSection,
                  bottom: false,
                  child: _buildTabBody(
                    goalExams: goalExams,
                    otherExams: otherExams,
                    goalIds: goalIds,
                    examsLoading: examsLoading,
                  ),
                ),
              ),
              // Hide the main Tests/Progress/Profile nav while inside a section
              // — there the exam dashboard shows its own floating tab bar.
              if (!insideSection)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Android-web only: "get the app" banner above the nav.
                      const GetAppBanner(),
                      _BottomNav(
                        currentIndex: _activeTab,
                        onTap: (index) => setState(() => _activeTab = index),
                        hasGoals: goalExams.isNotEmpty,
                      ),
                    ],
                  ),
                ),
            ],
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
        // "Tests" tab: category sections → drill into an exam's dashboard, which
        // now also hosts the per-exam Planner and Focus tools.
        return _buildExploreTab(goalExams, goalIds, examsLoading);
      case 1:
        // Bottom padding so content clears the floating nav bar.
        return Padding(
          padding: const EdgeInsets.only(bottom: 88),
          child: AnalyticsScreen(allExams: allExams, embedded: true),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.only(bottom: 88),
          child: _ProfileTab(
            user: widget.user,
            goalExams: goalExams,
            allExams: allExams,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  /// "Tests" tab. Landing shows category SECTIONS; tapping one drills into that
  /// category's old-home layout (exam rail at top + dashboard below).
  Widget _buildExploreTab(
      List<ExamModel> goalExams, Set<String> goalIds, bool examsLoading) {
    if (examsLoading || !_categoriesLoaded) {
      return const PercentLoaderCentered();
    }
    // Drilled into a category → old-home rail + dashboard for its exams.
    if (_testsCategoryId != null) {
      return _buildCategoryRoom(_testsCategoryId!);
    }
    // Landing: the category sections.
    return _buildCategorySections();
  }

  int _examCountInCategory(String catId) =>
      allExams.where((e) => e.category == catId).length;

  Widget _buildCategorySections() {
    final visible =
        _categories.where((c) => _examCountInCategory(c.id) > 0).toList();
    if (visible.isEmpty) {
      return Center(
        child: Text('No exams available yet.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
      );
    }
    return GridView.builder(
            // Bottom padding clears the floating translucent nav bar.
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Taller cells for the illustration-top / text-below layout.
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final c = visible[index];
              return GestureDetector(
                onTap: () => setState(() => _testsCategoryId = c.id),
                child: _CategorySectionCard(
                  categoryId: c.id,
                  label: c.label,
                  count: _examCountInCategory(c.id),
                  icon: categoryIconFor(c.icon),
                ),
              );
            },
    );
  }

  void _exitCategoryRoom() {
    _categorySearchCtrl.clear();
    setState(() {
      _testsCategoryId = null;
      _testsSelectedExam = null;
      _categorySearch = '';
    });
  }

  /// Category room: search + pick an exam from this category's themed grid.
  /// Selecting one swaps in its embedded dashboard right here (no switcher
  /// rail, no separate route) — back returns to the grid, not the sections.
  Widget _buildCategoryRoom(String catId) {
    final exams = allExams.where((e) => e.category == catId).toList();
    if (exams.isEmpty) {
      // Category emptied out — bounce back to sections.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _exitCategoryRoom();
      });
      return const SizedBox();
    }

    final category = _categories.firstWhere((c) => c.id == catId,
        orElse: () => _HomeCategory(catId, catId, 0, ''));
    final label = category.label;
    final accent = CategoryTheme.accentFor(catId);
    final selected = _testsSelectedExam;

    // Inside an exam's embedded dashboard: back returns to this category's grid.
    if (selected != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _testsSelectedExam = null);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: accent),
                    onPressed: () =>
                        setState(() => _testsSelectedExam = null),
                  ),
                  Expanded(
                    child: Text(selected.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: EmbeddedDashboard(
                  key: ValueKey(selected.id),
                  exam: selected,
                  user: widget.user,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final q = _categorySearch.trim().toLowerCase();
    final visibleExams = q.isEmpty
        ? exams
        : exams.where((e) => e.name.toLowerCase().contains(q)).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitCategoryRoom();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plain header row — matches AppTopBar's style used everywhere else.
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textPrimary, size: 20),
                  onPressed: _exitCategoryRoom,
                ),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingMd),
                ),
                Text('${exams.length} ${exams.length == 1 ? 'exam' : 'exams'}',
                    style: AppTheme.caption),
              ],
            ),
          ),
          // Plain search bar — same style as AllExamsScreen's.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight, width: 1.5),
              ),
              child: TextField(
                controller: _categorySearchCtrl,
                onChanged: (v) => setState(() => _categorySearch = v),
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                cursorColor: AppTheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search $label exams...',
                  hintStyle: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.55),
                      fontSize: 13.5),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.65),
                      size: 18),
                  suffixIcon: _categorySearch.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _categorySearchCtrl.clear();
                            setState(() => _categorySearch = '');
                          },
                          child: Icon(Icons.close_rounded,
                              color: AppTheme.textSecondary
                                  .withValues(alpha: 0.65),
                              size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          Expanded(
            child: visibleExams.isEmpty
                ? Center(
                    child: Text('No exams match "$_categorySearch"',
                        style: AppTheme.bodySm),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: visibleExams.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.space3),
                    itemBuilder: (context, index) {
                      final exam = visibleExams[index];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _testsSelectedExam = exam),
                        child: _CategoryExamCard(
                          exam: exam,
                          fallbackIcon: categoryIconFor(category.icon),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Plain list-row card for the category room's exam list — icon, name, and a
/// chevron. Same tokens (radius, shadow, borders) as the rest of the app.
class _CategoryExamCard extends StatelessWidget {
  const _CategoryExamCard({required this.exam, required this.fallbackIcon});
  final ExamModel exam;

  /// Shown instead of ExamIcon's generic school icon when this exam has
  /// neither a named iconKey nor a usable image — the category's own icon
  /// (e.g. the pillar icon for State PSC) reads better than a blank default.
  final IconData fallbackIcon;

  bool get _hasOwnIcon =>
      (exam.iconKey.isNotEmpty && kCategoryIcons.containsKey(exam.iconKey)) ||
      exam.icon.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.brLg,
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _hasOwnIcon
                  ? ExamIcon(
                      iconKey: exam.iconKey,
                      imageUrl: exam.icon,
                      size: 22,
                    )
                  : Icon(fallbackIcon, size: 22, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Text(exam.name,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: AppTheme.headingSm.copyWith(fontSize: 14)),
          ),
          const SizedBox(width: AppTheme.space3),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textLight, size: 22),
        ],
      ),
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
      const _NavItem(Icons.assignment_rounded, 'Tests'),
      const _NavItem(Icons.insights_rounded, 'Progress'),
      const _NavItem(Icons.person_rounded, 'Profile'),
    ];

    // Floating frosted pill: translucent + blurred backdrop for a light,
    // premium feel that lets content subtly show through underneath.
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPad > 0 ? bottomPad : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 23,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
              }).toList(),
            ),
          ),
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

class _HomeCategory {
  _HomeCategory(this.id, this.label, this.order, this.icon);
  final String id;
  final String label;
  final int order;
  final String icon;
}

class _CategorySectionCard extends StatelessWidget {
  const _CategorySectionCard(
      {required this.categoryId,
      required this.label,
      required this.count,
      required this.icon});
  final String categoryId;
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = CategoryTheme.accentFor(categoryId);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed illustration (falls back to an accent gradient) ──
          _Banner(categoryId: categoryId, accent: accent, icon: icon),

          // ── Dark scrim rising from the bottom for text legibility ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.35, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── Text on top ──
          Positioned(
            left: 14,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 6),
                      ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text('$count ${count == 1 ? 'exam' : 'exams'}',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Category banner: shows the bundled illustration if present, otherwise an
/// accent-tinted icon panel. Uses the async existence cache so it settles to the
/// image once (and never flickers on rebuilds).
class _Banner extends StatelessWidget {
  const _Banner(
      {required this.categoryId, required this.accent, required this.icon});
  final String categoryId;
  final Color accent;
  final IconData icon;

  // Full-bleed accent gradient with a faint icon — used when a category has no
  // bundled illustration. The card's dark scrim + white text still read well.
  Widget _fallback() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent,
              Color.lerp(accent, Colors.black, 0.28)!,
            ],
          ),
        ),
        child: Align(
          alignment: const Alignment(0, -0.25),
          child: Icon(icon,
              color: Colors.white.withValues(alpha: 0.9), size: 40),
        ),
      );

  Widget _image() => ClipRect(
        child: Transform.translate(
          // Slide the artwork up so the illustration's baked-in top headline is
          // pushed out of frame (the card shows its own name at the bottom).
          offset: const Offset(0, -40),
          child: Transform.scale(
            scale: 1.3,
            alignment: Alignment.topCenter,
            child: Image.asset(
              CategoryTheme.assetFor(categoryId),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cached = CategoryTheme.cachedHasImage(categoryId);
    if (cached == true) return _image();
    if (cached == false) return _fallback();
    // Unknown yet — resolve once, show fallback until known.
    return FutureBuilder<bool>(
      future: CategoryTheme.hasImage(categoryId),
      builder: (_, snap) =>
          (snap.data == true) ? _image() : _fallback(),
    );
  }
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
                    const Center(child: PercentLoader(size: 40))
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
            child: SizedBox(
              width: 32,
              height: 32,
              child: ExamIcon(
                iconKey: exam.iconKey,
                imageUrl: exam.icon,
                size: 16,
                color: Colors.white,
              ),
            ),
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
                      child: ExamIcon(
                        iconKey: exam.iconKey,
                        imageUrl: exam.icon,
                        size: 28,
                      ),
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
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person_rounded,
                    color: AppTheme.primary, size: 26),
                const SizedBox(width: 8),
                Text(
                  'My Profile',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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

          // Options
          _ProfileOption(
            icon: Icons.workspace_premium_outlined,
            title: 'My Memberships',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MembershipsScreen(),
                ),
              );
            },
          ),
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
          _ProfileOption(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen()));
            },
          ),
          const SizedBox(height: 20),
          _ProfileOption(
            icon: GuestGate.isGuest ? Icons.login_rounded : Icons.logout_rounded,
            title: GuestGate.isGuest ? 'Sign In' : 'Log Out',
            isDestructive: !GuestGate.isGuest,
            onTap: () async {
              if (GuestGate.isGuest) {
                showSignInSheet(context);
                return;
              }
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignIn()),
                  (r) => false,
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
