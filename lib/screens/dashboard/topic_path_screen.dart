import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/subject_model.dart';
import 'package:percent/models/topic_model.dart';
import 'package:percent/screens/dashboard/topic_content_screen.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/slim_header.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Topic PATH screen — candy-crush style winding S-curve of topic nodes.
//
// Node states:
//   completed  → brand gradient fill + check
//   current    → first incomplete unlocked topic, pulsing highlight
//   locked     → greyed with lock (previous topic not yet completed)
// First topic is always unlocked.
// ══════════════════════════════════════════════════════════════════════════════

class TopicPathScreen extends StatefulWidget {
  const TopicPathScreen({Key? key, required this.subject}) : super(key: key);

  final SubjectModel subject;

  @override
  State<TopicPathScreen> createState() => _TopicPathScreenState();
}

class _TopicPathScreenState extends State<TopicPathScreen>
    with SingleTickerProviderStateMixin {
  List<TopicModel> _topics = [];
  Set<String> _completed = {};
  bool _loading = true;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  // Vertical spacing between consecutive nodes.
  static const double _rowHeight = 130;
  static const double _nodeSize = 72;
  static const double _topPad = 32;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = FirebaseDatabase.instance;
    final topicsSnap = await db
        .ref('topics')
        .orderByChild('subjectId')
        .equalTo(widget.subject.id)
        .once();

    List<TopicModel> topics = [];
    if (topicsSnap.snapshot.value != null) {
      final raw = topicsSnap.snapshot.value as Map;
      topics = raw.values.map((v) => TopicModel.fromMap(v as Map)).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
    }

    final Set<String> completed = {};
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final progSnap = await db.ref('topicProgress/$uid').once();
      if (progSnap.snapshot.value != null) {
        final raw = Map<dynamic, dynamic>.from(progSnap.snapshot.value as Map);
        raw.forEach((k, v) {
          if (v == true) completed.add(k.toString());
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _topics = topics;
      _completed = completed;
      _loading = false;
    });
  }

  /// First incomplete topic index (the "current" node). -1 if all complete.
  int get _currentIndex {
    for (int i = 0; i < _topics.length; i++) {
      if (!_completed.contains(_topics[i].id)) return i;
    }
    return -1;
  }

  bool _isUnlocked(int i) {
    if (i == 0) return true;
    if (_completed.contains(_topics[i].id)) return true;
    // Unlocked when the previous topic is completed.
    return _completed.contains(_topics[i - 1].id);
  }

  Future<void> _openTopic(TopicModel topic) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TopicContentScreen(topic: topic),
      ),
    );
    // Refresh progress if the content screen marked completion.
    if (result == true && mounted) {
      setState(() => _completed = {..._completed, topic.id});
    }
  }

  // Horizontal position for a node: zig-zag left → center → right → center …
  double _fractionForIndex(int i) {
    switch (i % 4) {
      case 0:
        return 0.22; // left
      case 1:
        return 0.5; // center
      case 2:
        return 0.78; // right
      default:
        return 0.5; // center
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const PercentLoaderCentered()
                : _topics.isEmpty
                    ? _buildEmpty()
                    : _buildPath(),
          ),
        ],
      ),
    );
  }

  Widget _buildPath() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalHeight = _topPad + _topics.length * _rowHeight + 40;
        final centers = <Offset>[];
        for (int i = 0; i < _topics.length; i++) {
          final cx = width * _fractionForIndex(i);
          final cy = _topPad + i * _rowHeight + _nodeSize / 2;
          centers.add(Offset(cx, cy));
        }

        return SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: totalHeight,
            child: Stack(
              children: [
                // Dashed connecting curve behind the nodes.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PathPainter(
                      centers: centers,
                      completedFlags: [
                        for (int i = 0; i < _topics.length; i++)
                          _completed.contains(_topics[i].id)
                      ],
                    ),
                  ),
                ),
                // Nodes + labels.
                for (int i = 0; i < _topics.length; i++)
                  _buildNode(i, centers[i], width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(int i, Offset center, double width) {
    final topic = _topics[i];
    final bool completed = _completed.contains(topic.id);
    final bool unlocked = _isUnlocked(i);
    final bool isCurrent = i == _currentIndex;

    final labelOnLeft = center.dx > width * 0.6;

    Widget node = _NodeCircle(
      number: i + 1,
      completed: completed,
      unlocked: unlocked,
      isCurrent: isCurrent,
      size: _nodeSize,
      pulse: _pulseCtrl,
    );

    if (unlocked) {
      node = GestureDetector(onTap: () => _openTopic(topic), child: node);
    }

    // Label placed to the side of the node so it never overlaps the path.
    final labelWidth = width * 0.42;
    final children = <Widget>[
      Positioned(
        left: center.dx - _nodeSize / 2,
        top: center.dy - _nodeSize / 2,
        child: node,
      ),
      Positioned(
        top: center.dy - 20,
        left: labelOnLeft ? null : center.dx + _nodeSize / 2 + 10,
        right: labelOnLeft ? width - (center.dx - _nodeSize / 2) + 10 : null,
        width: labelWidth,
        child: Align(
          alignment: labelOnLeft ? Alignment.centerRight : Alignment.centerLeft,
          child: _NodeLabel(
            name: topic.name,
            completed: completed,
            unlocked: unlocked,
            alignRight: labelOnLeft,
          ),
        ),
      ),
    ];

    return Stack(children: children);
  }

  Widget _buildHeader(BuildContext context) {
    final done = _topics.where((t) => _completed.contains(t.id)).length;
    final total = _topics.length;
    return SlimHeader(
      eyebrow: 'Learning Path',
      title: widget.subject.name,
      onBack: () => Navigator.pop(context),
      trailing: (!_loading && total > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$done / $total',
                  style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
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
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.route_rounded,
                  size: 38, color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 18),
            Text('No topics yet',
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Topics for this subject will appear here soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Node circle ──────────────────────────────────────────────────────────────

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({
    required this.number,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.size,
    required this.pulse,
  });

  final int number;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final double size;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final core = _buildCore();
    if (isCurrent && unlocked && !completed) {
      // Pulsing ring around the current node.
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = pulse.value; // 0..1
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 18 * t + 6,
                height: size + 18 * t + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.18 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: core,
      );
    }
    return core;
  }

  Widget _buildCore() {
    if (completed) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
      );
    }
    if (unlocked) {
      // Current / available topic — white filled, indigo border + number.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text('$number',
              style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
        ),
      );
    }
    // Locked.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xffE9EDF3),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      child: Icon(Icons.lock_rounded,
          color: AppTheme.textLight.withValues(alpha: 0.9), size: 28),
    );
  }
}

// ── Node label ───────────────────────────────────────────────────────────────

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({
    required this.name,
    required this.completed,
    required this.unlocked,
    required this.alignRight,
  });

  final String name;
  final bool completed;
  final bool unlocked;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.inter(
            color: unlocked ? AppTheme.textPrimary : AppTheme.textLight,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          completed
              ? 'Completed'
              : unlocked
                  ? 'Tap to learn'
                  : 'Locked',
          style: GoogleFonts.inter(
            color: completed
                ? AppTheme.success
                : unlocked
                    ? AppTheme.primary
                    : AppTheme.textLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Dashed curved connector between nodes ───────────────────────────────────

class _PathPainter extends CustomPainter {
  _PathPainter({required this.centers, required this.completedFlags});

  final List<Offset> centers;
  final List<bool> completedFlags;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    for (int i = 0; i < centers.length - 1; i++) {
      final p1 = centers[i];
      final p2 = centers[i + 1];
      // Curved segment: control points create the S-curve feel.
      final path = Path()..moveTo(p1.dx, p1.dy);
      final midY = (p1.dy + p2.dy) / 2;
      path.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);

      // Segment is "active" (solid gradient) when its start node is completed.
      final bool active = completedFlags[i];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 5 : 4
        ..strokeCap = StrokeCap.round
        ..color = active
            ? AppTheme.primary.withValues(alpha: 0.55)
            : AppTheme.border;

      _drawDashedPath(canvas, path, paint, active);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, bool active) {
    const double dashLen = 10;
    const double gapLen = 8;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dashLen, metric.length);
        final seg = metric.extractPath(dist, next);
        canvas.drawPath(seg, paint);
        dist = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.centers != centers || old.completedFlags != completedFlags;
}
