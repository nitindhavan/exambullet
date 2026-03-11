import 'package:percent/models/exam.dart';
import 'package:percent/models/test_model.dart';
import 'package:percent/screens/membership_screen.dart';
import 'package:percent/screens/test_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TestsTab extends StatelessWidget {
  const TestsTab(
      {Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('tests')
          .orderByChild('examId')
          .equalTo(exam.id)
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff3D1975)));
        }
        final tests = snapshot.data!.snapshot.children
            .map((s) => TestModel.fromMap(s.value as Map))
            .toList();

        if (tests.isEmpty) {
          return const _EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No tests yet',
            subtitle: 'Mock tests for this exam will appear here.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text('Mock Tests',
                      style: TextStyle(
                          color: Color(0xff2D0F5E),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  _Chip('${tests.length} tests'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: tests.length,
                itemBuilder: (ctx, i) => _TestCard(
                  test: tests[i],
                  index: i,
                  hasMembership: hasMembership,
                  examId: exam.id,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.index,
    required this.hasMembership,
    required this.examId,
  });
  final TestModel test;
  final int index;
  final bool hasMembership;
  final String examId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (hasMembership) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => TestScreen(testModel: test)));
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => MemberShipScreen(model: examId)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3D1975).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff3D1975), Color(0xff6B3FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.name,
                      style: const TextStyle(
                          color: Color(0xff1A0540),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${test.time} mins',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            if (!hasMembership)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xffFFF3E0),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.lock_rounded,
                    size: 16, color: Color(0xffFF9800)),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: Color(0xff3D1975)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff3D1975).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xff3D1975),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.06),
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 40,
                  color: const Color(0xff3D1975).withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}