import 'package:percent/models/exam.dart';
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

class _AllExamsScreenState extends State<AllExamsScreen> {
  late final TextEditingController _searchCtrl;
  String _search = '';
  late Set<String> _goalIds;

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
    _searchCtrl = TextEditingController(text: widget.initialSearch);
    _goalIds = Set<String>.from(widget.goalIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ExamModel> _filterExams() {
    if (_search.isEmpty) return widget.allExams;
    final q = _search.toLowerCase();
    return widget.allExams.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _toggleGoal(String examId) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterExams();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Choose Your Goals'),
      body: Column(
        children: [
          // ── Search ──
          _buildSearchBar(context),

          // ── Catalog Grid ──
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.84,
                    ),
                    itemBuilder: (context, index) {
                      final exam = filtered[index];
                      final isGoal = _goalIds.contains(exam.id);
                      return GestureDetector(
                        onTap: () => _toggleGoal(exam.id),
                        child: _ExamCard(
                          exam: exam,
                          isGoal: isGoal,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
                        child: Image.network(
                          exam.icon,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.school_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
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
