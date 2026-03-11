import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/all_exams_screen.dart';
import 'package:percent/screens/exam_dashboard.dart';
import 'package:percent/widgets/home/explore_section.dart';
import 'package:percent/widgets/home/goal_exams_section.dart';
import 'package:percent/widgets/home/home_header.dart';
import 'package:percent/widgets/home/news_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
      allExams =
          raw.entries.map((e) => ExamModel.fromMap(e.value as Map)).toList();
      examsLoading = false;
    });
  }

  void _openAllExams(Set<String> goalIds) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllExamsScreen(allExams: allExams, goalIds: goalIds),
      ),
    );
  }

  void _openExamDashboard(ExamModel exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDashboard(exam: exam, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0EBFF),
      body: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: _goalIdsStream,
          initialData: const {},
          builder: (context, snap) {
            final goalIds = snap.data ?? {};
            final goalExams =
                allExams.where((e) => goalIds.contains(e.id)).toList();
            final otherExams =
                allExams.where((e) => !goalIds.contains(e.id)).toList();

            return CustomScrollView(
              slivers: [
                // ── Sticky header ──────────────────────────
                SliverToBoxAdapter(
                  child: HomeHeader(
                    user: widget.user,
                    goalCount: goalExams.length,
                  ),
                ),

                SliverToBoxAdapter(
                  child: GoalExamsSection(
                    goalExams: goalExams,
                    examsLoading: examsLoading,
                    goalIds: goalIds,
                    onManageTap: () => _openAllExams(goalIds),
                    onExamTap: _openExamDashboard,
                  ),
                ),

                SliverToBoxAdapter(
                  child: NewsSection(goalExams: goalExams),
                ),

                SliverToBoxAdapter(
                  child: ExploreSection(
                    otherExams: otherExams,
                    examsLoading: examsLoading,
                    goalIds: goalIds,
                    onViewAllTap: () => _openAllExams(goalIds),
                    onExamTap: _openExamDashboard,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}
