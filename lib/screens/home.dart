import 'package:percent/main.dart';
import 'package:percent/models/User.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/membership_screen.dart';
import 'package:percent/screens/test_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/test_model.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.user}) : super(key: key);

  final UserModel user;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? selectedExamId;
  ExamModel? selectedExam;
  List<ExamModel> allExams = [];
  bool examsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllExams();
  }

  Future<void> _loadAllExams() async {
    final snap = await FirebaseDatabase.instance.ref('exams').once();
    if (snap.snapshot.value == null) return;
    final map = snap.snapshot.value as Map;
    final list =
        map.entries.map((e) => ExamModel.fromMap(e.value as Map)).toList();
    setState(() {
      allExams = list;
      // default to origin exam
      selectedExamId = origin;
      selectedExam = list.firstWhere(
        (e) => e.id == origin,
        orElse: () => list.first,
      );
      examsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ─────────────────────────────────
            Container(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // greeting row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${widget.user.name.split(' ').first} 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Ready to practice today?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Exam selector chips ──────────────────
                  const Text(
                    'Select Exam',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  examsLoading
                      ? const SizedBox(
                          height: 40,
                          child: Center(
                            child: LinearProgressIndicator(
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allExams.length,
                            itemBuilder: (context, index) {
                              final exam = allExams[index];
                              final isSelected = exam.id == selectedExamId;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedExamId = exam.id;
                                    selectedExam = exam;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    exam.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xff3D1975)
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),

            // ── Selected exam card ──────────────────────────
            if (selectedExam != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff3D1975).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        selectedExam!.icon,
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedExam!.name,
                            style: const TextStyle(
                              color: Color(0xff3D1975),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedExam!.about,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Tests section header ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Practice Tests',
                    style: TextStyle(
                      color: Color(0xff3D1975),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Tap to start',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tests list ─────────────────────────────────
            Expanded(
              child: selectedExamId == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff3D1975)))
                  : StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref('tests')
                          .orderByChild('examId')
                          .equalTo(selectedExamId)
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff3D1975)),
                          );
                        }
                        List<TestModel> tests = [];
                        for (DataSnapshot s
                            in snapshot.data!.snapshot.children) {
                          tests.add(TestModel.fromMap(s.value as Map));
                        }
                        if (tests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No tests available yet',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: tests.length,
                          itemBuilder: (context, index) {
                            return _testCard(tests[index], index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testCard(TestModel test, int index) {
    return GestureDetector(
      onTap: () {
        FirebaseDatabase.instance
            .ref('memberships')
            .child(test.examId)
            .child(FirebaseAuth.instance.currentUser!.uid)
            .once()
            .then((value) {
          if (value.snapshot.exists) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TestScreen(testModel: test)));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MemberShipScreen(model: test.examId)));
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3D1975).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Index badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xff3D1975).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xff3D1975),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Test name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(
                      color: Color(0xff27124D),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to attempt',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Color(0xff3D1975)),
          ],
        ),
      ),
    );
  }
}
