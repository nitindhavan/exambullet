import 'package:flutter/material.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/test_result_model.dart';
import 'package:percent/services/test_analytics.dart';
import 'package:percent/services/test_result_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Analytics / progress dashboard built from the user's saved test attempts.
/// Results can be viewed for all exams together or filtered to one exam.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen(
      {Key? key, this.allExams = const [], this.embedded = false})
      : super(key: key);
  final List<ExamModel> allExams;

  /// When true the screen renders only its body (no Scaffold/AppBar) so it can
  /// live inside the home tab shell.
  final bool embedded;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _examId; // null = all exams

  String _examName(String id) {
    for (final e in widget.allExams) {
      if (e.id == id) return e.name;
    }
    return 'Exam';
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'My Progress'),
      body: body,
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<TestResult>>(
        stream: TestResultService.resultsStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const PercentLoaderCentered();
          }
          final all = snap.data!;
          if (all.isEmpty) return const _EmptyState();

          // Exams the user actually has attempts for (preserve most-recent order).
          final examIds = <String>[];
          for (final r in all) {
            if (r.examId.isNotEmpty && !examIds.contains(r.examId)) {
              examIds.add(r.examId);
            }
          }
          // Resolve to exam objects (for icons/names); fall back to a stub.
          final railExams = examIds
              .map((id) => widget.allExams.firstWhere(
                    (e) => e.id == id,
                    orElse: () => _stubExam(id, _examName(id)),
                  ))
              .toList();

          final filtered = _examId == null
              ? all
              : all.where((r) => r.examId == _examId).toList();
          final a = TestAnalytics(filtered);

          final content = a.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppTheme.space5,
                      AppTheme.space5, AppTheme.space5, AppTheme.space8),
                  children: [
                    const _SectionHeader(),
                    const SizedBox(height: AppTheme.space5),
                    _OverviewGrid(a: a),
                    const SizedBox(height: AppTheme.space6),
                    _ScoreTrendCard(points: a.scoreTrend),
                    const SizedBox(height: AppTheme.space6),
                    _AccuracyCard(a: a),
                    const SizedBox(height: AppTheme.space6),
                    if (a.topicPerformance.isNotEmpty) ...[
                      _TopicCard(
                        title: 'Focus areas',
                        subtitle: 'Your weakest topics — revise these first',
                        topics: a.weakestTopics(5),
                      ),
                      const SizedBox(height: AppTheme.space6),
                      _TopicCard(
                        title: 'Your strengths',
                        subtitle: 'Topics you consistently get right',
                        topics: a.strongestTopics(5),
                      ),
                      const SizedBox(height: AppTheme.space6),
                    ],
                    _HistoryCard(results: filtered),
                  ],
                );

          if (railExams.length <= 1) return content;

          // Rail on top, content in a connected rounded-white panel with a top
          // shadow — the same pattern as the Planner tab.
          return Column(
            children: [
              _ExamRail(
                exams: railExams,
                selectedId: _examId,
                onSelect: (id) => setState(() => _examId = id),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
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
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    child: content,
                  ),
                ),
              ),
            ],
          );
        });
  }
}

// ── Exam switcher rail (matches PlannerTab's rail) ──────────────────────────────

/// Builds a lightweight [ExamModel] for an exam we have results for but that
/// isn't in the passed-in list (e.g. an exam the user later removed as a goal).
ExamModel _stubExam(String id, String name) =>
    ExamModel.fromMap({'id': id, 'name': name, 'visible': true}, id);

class _ExamRail extends StatelessWidget {
  const _ExamRail({
    required this.exams,
    required this.selectedId,
    required this.onSelect,
  });
  final List<ExamModel> exams;
  final String? selectedId; // null = All Exams
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        children: [
          // "All Exams" tile.
          _RailTile(
            label: 'All Exams',
            isSelected: selectedId == null,
            onTap: () => onSelect(null),
            iconChild: const Icon(Icons.dashboard_rounded,
                color: AppTheme.primary, size: 22),
          ),
          for (final exam in exams)
            _RailTile(
              label: exam.name,
              isSelected: exam.id == selectedId,
              onTap: () => onSelect(exam.id),
              iconChild: ClipOval(
                child: ExamIcon(
                  iconKey: exam.iconKey,
                  imageUrl: exam.icon,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.iconChild,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget iconChild;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
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
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: iconChild),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: AppTheme.brMd,
          ),
          child: const Icon(Icons.insights_rounded,
              color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Progress', style: AppTheme.headingMd),
            Text('Your performance across tests', style: AppTheme.bodySm),
          ],
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.insights_rounded,
                  color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('No data yet', style: AppTheme.headingMd),
            const SizedBox(height: 8),
            Text(
              'Take a test and your performance analytics — score trends, weak topics, and history — will show up here.',
              textAlign: TextAlign.center,
              style: AppTheme.body,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview stat tiles ─────────────────────────────────────────────────────────

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.a});
  final TestAnalytics a;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Stat('Tests taken', '${a.testsTaken}', Icons.assignment_turned_in_rounded,
          AppTheme.primary),
      _Stat('Avg score', '${(a.avgScorePct * 100).round()}%',
          Icons.trending_up_rounded, AppTheme.success),
      _Stat('Accuracy', '${(a.overallAccuracy * 100).round()}%',
          Icons.my_location_rounded, AppTheme.warning),
      _Stat('Best score', '${(a.bestScorePct * 100).round()}%',
          Icons.emoji_events_rounded, AppTheme.primary),
    ];
    // Two rows of two content-sized tiles. No fixed aspect ratio, so cards grow
    // to fit their text on any screen — never overflows.
    Widget tile(_Stat t) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.12),
                    borderRadius: AppTheme.brSm,
                  ),
                  child: Icon(t.icon, color: t.color, size: 18),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(t.value,
                    style: AppTheme.headingMd.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(t.label,
                    style: AppTheme.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              tile(tiles[0]),
              const SizedBox(width: AppTheme.space4),
              tile(tiles[1]),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        IntrinsicHeight(
          child: Row(
            children: [
              tile(tiles[2]),
              const SizedBox(width: AppTheme.space4),
              tile(tiles[3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat {
  _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

// ── Score trend (line chart) ─────────────────────────────────────────────────────

class _ScoreTrendCard extends StatelessWidget {
  const _ScoreTrendCard({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score over time', style: AppTheme.headingMd),
          const SizedBox(height: 2),
          Text('Each point is one test, oldest to newest',
              style: AppTheme.bodySm),
          const SizedBox(height: AppTheme.space5),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: points.length < 2
                ? Center(
                    child: Text('Take a few more tests to see your trend',
                        style: AppTheme.bodySm))
                : CustomPaint(
                    painter: _TrendPainter(
                        points.map((p) => p.pct).toList()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<double> values; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 6.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Gridlines at 0/50/100%.
    final grid = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = pad + h * (1 - f);
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), grid);
    }

    Offset pointAt(int i) {
      final x = pad + (values.length == 1 ? 0 : w * i / (values.length - 1));
      final y = pad + h * (1 - values[i].clamp(0, 1));
      return Offset(x, y);
    }

    // Area fill under the line.
    final area = Path()..moveTo(pad, pad + h);
    for (int i = 0; i < values.length; i++) {
      area.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    area.lineTo(pad + w, pad + h);
    area.close();
    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withValues(alpha: 0.20),
              AppTheme.primary.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(pad, pad, w, h)));

    // The line (2px, primary).
    final line = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(path, line);

    // Markers with a 2px surface ring.
    for (int i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(pointAt(i), 4.5,
          Paint()..color = AppTheme.primary..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}

// ── Accuracy breakdown ───────────────────────────────────────────────────────────

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.a});
  final TestAnalytics a;

  @override
  Widget build(BuildContext context) {
    final total = a.totalCorrect + a.totalWrong + a.totalSkipped;
    final segments = <_Seg>[
      _Seg('Correct', a.totalCorrect, AppTheme.success),
      _Seg('Wrong', a.totalWrong, AppTheme.error),
      _Seg('Skipped', a.totalSkipped, AppTheme.textSecondary),
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Answer breakdown', style: AppTheme.headingMd),
          const SizedBox(height: 2),
          Text('Across all $total questions attempted', style: AppTheme.bodySm),
          const SizedBox(height: AppTheme.space5),
          // Stacked bar with 2px surface gaps.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: total == 0
                  ? Container(color: AppTheme.borderLight)
                  : Row(
                      children: [
                        for (int i = 0; i < segments.length; i++)
                          if (segments[i].value > 0) ...[
                            Expanded(
                              flex: segments[i].value,
                              child: Container(color: segments[i].color),
                            ),
                            if (i != segments.length - 1)
                              const SizedBox(width: 2),
                          ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          Wrap(
            spacing: AppTheme.space5,
            runSpacing: AppTheme.space3,
            children: [
              for (final s in segments)
                _LegendDot(color: s.color, label: s.label, value: s.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seg {
  _Seg(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ',
            style: AppTheme.bodySm.copyWith(color: AppTheme.textSecondary)),
        Text('$value',
            style: AppTheme.bodySm
                .copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Topic performance bars ───────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard(
      {required this.title, required this.subtitle, required this.topics});
  final String title;
  final String subtitle;
  final List<TopicPerformance> topics;

  Color _accColor(double acc) {
    if (acc >= 0.7) return AppTheme.success;
    if (acc >= 0.4) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMd),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTheme.bodySm),
          const SizedBox(height: AppTheme.space5),
          for (final t in topics) ...[
            _TopicRow(topic: t, color: _accColor(t.stat.accuracy)),
            if (t != topics.last) const SizedBox(height: AppTheme.space4),
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.color});
  final TopicPerformance topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final acc = topic.stat.accuracy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(topic.topic,
                  style: AppTheme.body
                      .copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text('${(acc * 100).round()}%',
                style: AppTheme.bodySm
                    .copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 8, color: AppTheme.borderLight),
              FractionallySizedBox(
                widthFactor: acc.clamp(0.02, 1),
                child: Container(height: 8, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('${topic.stat.correct}/${topic.stat.attempted} correct',
            style: AppTheme.caption),
      ],
    );
  }
}

// ── Attempt history ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.results});
  final List<TestResult> results; // newest first

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final show = results.take(20).toList();
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent tests', style: AppTheme.headingMd),
          const SizedBox(height: AppTheme.space5),
          for (final r in show) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.testName.isEmpty ? 'Test' : r.testName,
                          style: AppTheme.body.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                          '${_fmtDate(r.takenAt)} · ${r.correct}/${r.questionCount} correct',
                          style: AppTheme.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${(r.scorePct * 100).round()}%',
                      style: AppTheme.bodySm.copyWith(
                          color: AppTheme.primary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (r != show.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space4),
                child: Divider(height: 1, color: AppTheme.borderLight),
              ),
          ],
        ],
      ),
    );
  }
}
