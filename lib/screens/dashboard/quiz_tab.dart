import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/subject_model.dart';
import 'package:percent/screens/dashboard/topic_path_screen.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';

// ══════════════════════════════════════════════════════════════════════════════
// QuizTab  —  subjects list
// ══════════════════════════════════════════════════════════════════════════════

class QuizTab extends StatefulWidget {
  const QuizTab({Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<SubjectModel> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final snap = await FirebaseDatabase.instance
        .ref('subjects')
        .orderByChild('examId')
        .equalTo(widget.exam.id)
        .once();
    if (!mounted) return;
    List<SubjectModel> list = [];
    if (snap.snapshot.value != null) {
      final raw = snap.snapshot.value as Map;
      list = raw.values.map((v) => SubjectModel.fromMap(v as Map)).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
    }
    setState(() {
      _subjects = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PercentLoaderCentered();
    }
    if (_subjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        subtitle: 'Practice subjects will appear here soon.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
          child: Text('Choose a Subject', style: AppTheme.headingMd),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Learn topic-by-topic with curated videos',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            itemCount: _subjects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (_, i) {
              final subject = _subjects[i];
              final color = _subjectColors[i % _subjectColors.length];
              final icon = _subjectIcons[i % _subjectIcons.length];
              return _SubjectCard(
                name: subject.name,
                color: color,
                icon: icon,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicPathScreen(
                        subject: subject,
                        examId: widget.exam.id,
                        hasMembership: widget.hasMembership),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Clean subject tile: gradient icon medallion, name, and a subtle accent.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard(
      {required this.name,
      required this.color,
      required this.icon,
      required this.onTap});
  final String name;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Soft accent blob in the corner.
            Positioned(
              top: -24, right: -24,
              child: Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          color,
                          Color.lerp(color, Colors.black, 0.18)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.headingSm.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Start learning',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: color),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _subjectColors = [
  Color(0xff10B981), // Emerald
  Color(0xff3B82F6), // Blue
  Color(0xffF59E0B), // Amber
  Color(0xff8B5CF6), // Violet
  Color(0xffEF4444), // Red
  Color(0xff06B6D4), // Cyan
  Color(0xffEC4899), // Pink
  Color(0xffF97316), // Orange
];

const _subjectIcons = [
  Icons.menu_book_rounded,
  Icons.public_rounded,
  Icons.account_balance_rounded,
  Icons.calculate_rounded,
  Icons.science_rounded,
  Icons.psychology_rounded,
  Icons.history_edu_rounded,
  Icons.newspaper_rounded,
];

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
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 40, color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
