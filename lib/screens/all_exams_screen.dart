import 'package:percent/models/exam.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/services/guest_gate.dart';
import 'package:percent/utils/category_icons.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/sign_in_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

class AllExamsScreen extends StatefulWidget {
  const AllExamsScreen({
    Key? key,
    required this.allExams,
    required this.goalIds,
    this.initialSearch = '',
  }) : super(key: key);

  final List<ExamModel> allExams;
  final Set<String> goalIds;
  final String initialSearch;

  @override
  State<AllExamsScreen> createState() => _AllExamsScreenState();
}

class _Category {
  _Category(this.id, this.label, this.order, this.icon);
  final String id;
  final String label;
  final int order;
  final String icon;
}

class _AllExamsScreenState extends State<AllExamsScreen> {
  late final TextEditingController _searchCtrl;
  String _search = '';
  late Set<String> _goalIds;

  List<_Category> _categories = [];
  String? _selectedCategory; // null = showing category tiles
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
    _searchCtrl = TextEditingController(text: widget.initialSearch);
    _goalIds = Set<String>.from(widget.goalIds);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('categories').once();
      final cats = <_Category>[];
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        final data = snap.snapshot.value as Map;
        data.forEach((key, v) {
          final m = v as Map;
          cats.add(_Category(
            key.toString(),
            (m['label'] ?? key).toString(),
            (m['order'] as num?)?.toInt() ?? 999,
            (m['icon'] ?? '').toString(),
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
    _searchCtrl.dispose();
    super.dispose();
  }

  int _countInCategory(String catId) =>
      widget.allExams.where((e) => e.category == catId).length;

  /// Exams for the current view: search results (across all) if searching,
  /// otherwise the selected category's exams.
  List<ExamModel> _visibleExams() {
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return widget.allExams
          .where((e) => e.name.toLowerCase().contains(q))
          .toList();
    }
    if (_selectedCategory != null) {
      return widget.allExams
          .where((e) => e.category == _selectedCategory)
          .toList();
    }
    return const [];
  }

  Future<void> _toggleGoal(String examId) async {
    // Guests (anonymous web visitors) can browse, but saving a goal is worth
    // nudging them to sign in so it isn't lost. They can still dismiss and the
    // goal saves to their guest account either way — so only nudge, don't block.
    if (GuestGate.isGuest) {
      GuestGate.softNudge(context, reason: 'goal');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showSignInSheet(context);
      return;
    }
    final ref = FirebaseDatabase.instance.ref('users/$uid/goalExamIds/$examId');
    if (_goalIds.contains(examId)) {
      setState(() => _goalIds.remove(examId));
      await ref.remove();
    } else {
      setState(() => _goalIds.add(examId));
      await ref.set(true);
      final match = widget.allExams.where((e) => e.id == examId);
      Analytics.instance.logAddGoal(
          examId, match.isNotEmpty ? match.first.name : examId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show category tiles only when not searching and no category picked.
    final showingCategories = _search.isEmpty && _selectedCategory == null;
    final exams = _visibleExams();

    // When viewing a category's exams, back should return to the category grid.
    final inCategoryView = _selectedCategory != null && _search.isEmpty;

    return PopScope(
      canPop: !inCategoryView,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inCategoryView) {
          setState(() => _selectedCategory = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppTopBar(
          title: inCategoryView ? _categoryLabel(_selectedCategory!) : 'Add Exams',
          onBack: inCategoryView
              ? () => setState(() => _selectedCategory = null)
              : null,
        ),
        body: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: showingCategories
                  ? _buildCategoryGrid()
                  : (exams.isEmpty
                      ? _emptyState()
                      : _buildExamGrid(exams)),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String id) =>
      _categories.firstWhere((c) => c.id == id,
              orElse: () => _Category(id, id, 0, ''))
          .label;

  Widget _buildCategoryGrid() {
    if (!_categoriesLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    // Hide empty categories.
    final visible =
        _categories.where((c) => _countInCategory(c.id) > 0).toList();
    if (visible.isEmpty) return _emptyState();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final c = visible[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = c.id),
          child: _CategoryCard(
            label: c.label,
            count: _countInCategory(c.id),
            icon: categoryIconFor(c.icon),
          ),
        );
      },
    );
  }

  Widget _buildExamGrid(List<ExamModel> exams) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: exams.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (context, index) {
        final exam = exams[index];
        final isGoal = _goalIds.contains(exam.id);
        return GestureDetector(
          onTap: () => _toggleGoal(exam.id),
          child: _ExamCard(exam: exam, isGoal: isGoal),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Minimalist Search Input ──
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight, width: 1.5),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              cursorColor: AppTheme.primary,
              decoration: InputDecoration(
                hintText: 'Search exams (e.g. JEE, UPSC...)',
                hintStyle: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.55), fontSize: 13.5),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary.withValues(alpha: 0.65), size: 18),
                suffixIcon: _search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: AppTheme.textSecondary.withValues(alpha: 0.65), size: 16),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No exams found',
              style: AppTheme.headingSm,
            ),
            const SizedBox(height: 6),
            Text(
              'We couldn\'t find any exams matching your search query. Try typing another keyword.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(
      {required this.label, required this.count, required this.icon});
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppTheme.headingSm.copyWith(fontSize: 14, height: 1.15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$count ${count == 1 ? 'exam' : 'exams'}',
                    style: AppTheme.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.isGoal,
  });

  final ExamModel exam;
  final bool isGoal;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGoal ? AppTheme.primary : AppTheme.borderLight,
          width: isGoal ? 2.0 : 1.5,
        ),
        boxShadow: isGoal
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isGoal
                        ? AppTheme.primaryLight.withValues(alpha: 0.2)
                        : AppTheme.borderLight.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ExamIcon(
                          iconKey: exam.iconKey,
                          imageUrl: exam.icon,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Title and button
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34,
                      child: Center(
                        child: Text(
                          exam.name,
                          textAlign: TextAlign.center,
                          style: AppTheme.headingSm.copyWith(
                            fontSize: 12,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isGoal ? AppTheme.primary : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGoal ? Icons.check_rounded : Icons.add_rounded,
                            size: 13,
                            color: isGoal ? Colors.white : AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGoal ? 'Goal Active' : 'Add Goal',
                            style: AppTheme.label.copyWith(
                              color: isGoal ? Colors.white : AppTheme.primary,
                              fontSize: 10,
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
          // Checkmark Badge at top-right if selected
          if (isGoal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
