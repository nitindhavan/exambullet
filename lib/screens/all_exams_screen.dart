import 'package:percent/models/exam.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AllExamsScreen extends StatefulWidget {
  const AllExamsScreen({
    Key? key,
    required this.allExams,
    required this.goalIds,
  }) : super(key: key);

  final List<ExamModel> allExams;
  final Set<String> goalIds;

  @override
  State<AllExamsScreen> createState() => _AllExamsScreenState();
}

class _AllExamsScreenState extends State<AllExamsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  late Set<String> _goalIds;

  @override
  void initState() {
    super.initState();
    _goalIds = Set<String>.from(widget.goalIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ExamModel> _filtered(List<ExamModel> src) {
    if (_search.isEmpty) return src;
    final q = _search.toLowerCase();
    return src.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _toggleGoal(String examId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
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
    final goalExams = _filtered(
        widget.allExams.where((e) => _goalIds.contains(e.id)).toList());
    final otherExams = _filtered(
        widget.allExams.where((e) => !_goalIds.contains(e.id)).toList());

    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 28),
                children: [
                  if (goalExams.isNotEmpty) ...[
                    _sectionHeader(
                      icon: Icons.flag_rounded,
                      label: 'My Goals',
                      count: goalExams.length,
                      color: const Color(0xff3D1975),
                    ),
                    _buildGrid(goalExams, isGoal: true),
                  ],
                  _sectionHeader(
                    icon: Icons.explore_rounded,
                    label: 'All Exams',
                    count: otherExams.length,
                    color: const Color(0xff6B3FA0),
                  ),
                  if (otherExams.isEmpty)
                    _emptyState()
                  else
                    _buildGrid(otherExams, isGoal: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ExamModel> exams, {required bool isGoal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: exams.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final exam = exams[index];
          return _ExamCard(
            exam: exam,
            isGoal: isGoal,
            onToggle: () => _toggleGoal(exam.id),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2A0D5E), Color(0xff6B3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Exams',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pin exams to track them on home',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${_goalIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search exams...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.65), size: 20),
                suffixIcon: _search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withOpacity(0.65), size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              _search.isNotEmpty
                  ? 'No exams match "$_search"'
                  : 'All exams are in your goals!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
    required this.onToggle,
  });

  final ExamModel exam;
  final bool isGoal;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isGoal
            ? Border.all(
                color: const Color(0xff3D1975).withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff3D1975).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xff3D1975).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff3D1975).withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    exam.icon,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school_rounded,
                      color: Color(0xff3D1975),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Name + badge + button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    exam.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff2D0F5E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isGoal
                            ? const Color(0xff3D1975)
                            : const Color(0xff3D1975).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGoal ? Icons.check_rounded : Icons.add_rounded,
                            size: 13,
                            color:
                                isGoal ? Colors.white : const Color(0xff3D1975),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGoal ? 'Pinned' : 'Pin',
                            style: TextStyle(
                              color: isGoal
                                  ? Colors.white
                                  : const Color(0xff3D1975),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
