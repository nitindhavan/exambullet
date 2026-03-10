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
  String _search = '';
  late Set<String> _goalIds;

  @override
  void initState() {
    super.initState();
    _goalIds = Set<String>.from(widget.goalIds);
  }

  List<ExamModel> get _sorted {
    final query = _search.toLowerCase();
    final filtered = query.isEmpty
        ? widget.allExams
        : widget.allExams
            .where((e) => e.name.toLowerCase().contains(query))
            .toList();
    // Goals pinned at top
    return [
      ...filtered.where((e) => _goalIds.contains(e.id)),
      ...filtered.where((e) => !_goalIds.contains(e.id)),
    ];
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
    final exams = _sorted;
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${_goalIds.length} in goals  ·  ${widget.allExams.length} total',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: exams.isEmpty
                  ? const Center(
                      child: Text('No exams found',
                          style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: exams.length,
                      itemBuilder: (_, i) => _examCard(exams[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff3D1975), Color(0xff6B3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Exams',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Tap the + button to add an exam to your goals',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search exams...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xff3D1975)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _examCard(ExamModel exam) {
    final isGoal = _goalIds.contains(exam.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isGoal
            ? Border.all(color: const Color(0xff3D1975), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff3D1975).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  exam.icon,
                  height: 105,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 105,
                    color: const Color(0xff3D1975).withOpacity(0.08),
                    child: const Icon(Icons.school_rounded,
                        color: Color(0xff3D1975), size: 36),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleGoal(exam.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isGoal
                          ? const Color(0xff3D1975)
                          : Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isGoal ? Icons.check_rounded : Icons.add_rounded,
                      color: isGoal ? Colors.white : const Color(0xff3D1975),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  style: const TextStyle(
                    color: Color(0xff27124D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isGoal ? 'Added to goals' : exam.about,
                  style: TextStyle(
                    color: isGoal
                        ? const Color(0xff3D1975).withOpacity(0.7)
                        : Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: isGoal ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
