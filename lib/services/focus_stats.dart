import 'package:percent/models/focus_session_model.dart';

/// Pure client-side aggregation over a user's focus sessions. Everything the
/// Focus tab renders (streak, heatmap, insights, per-exam breakdown) is derived
/// here so the widget layer stays declarative.
class FocusStats {
  /// Total seconds studied per local day, keyed by "YYYY-MM-DD".
  final Map<String, int> secondsByDay;

  /// Total seconds studied per exam, keyed by examId.
  final Map<String, int> secondsByExam;

  /// examId → display name (last seen).
  final Map<String, String> examNames;

  final int totalSec;
  final int sessionCount;
  final int currentStreak;
  final int longestStreak;

  FocusStats._({
    required this.secondsByDay,
    required this.secondsByExam,
    required this.examNames,
    required this.totalSec,
    required this.sessionCount,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory FocusStats.from(List<FocusSession> sessions, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final byDay = <String, int>{};
    final byExam = <String, int>{};
    final names = <String, String>{};
    var total = 0;

    for (final s in sessions) {
      byDay.update(s.day, (v) => v + s.durationSec,
          ifAbsent: () => s.durationSec);
      byExam.update(s.examId, (v) => v + s.durationSec,
          ifAbsent: () => s.durationSec);
      if (s.examName.isNotEmpty) names[s.examId] = s.examName;
      total += s.durationSec;
    }

    final streaks = _streaks(byDay.keys.toSet(), today);

    return FocusStats._(
      secondsByDay: byDay,
      secondsByExam: byExam,
      examNames: names,
      totalSec: total,
      sessionCount: sessions.length,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
    );
  }

  int secondsOn(DateTime day) => secondsByDay[_key(_dateOnly(day))] ?? 0;

  /// Exams sorted by time spent, descending.
  List<MapEntry<String, int>> get examsByTime {
    final entries = secondsByExam.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int get activeDays => secondsByDay.keys.length;

  int get bestDaySec =>
      secondsByDay.values.fold(0, (m, v) => v > m ? v : m);

  int get avgPerActiveDaySec =>
      activeDays == 0 ? 0 : totalSec ~/ activeDays;

  // ── streak computation ──────────────────────────────────────────────────────

  /// Returns current + longest streaks. A "current" streak counts back from
  /// today, but studying yesterday-but-not-yet-today still keeps it alive (so it
  /// doesn't reset to 0 first thing in the morning).
  static _Streaks _streaks(Set<String> activeDays, DateTime today) {
    if (activeDays.isEmpty) return const _Streaks(0, 0);

    // Longest run of consecutive active days.
    final sorted = activeDays.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final cur = DateTime.parse(sorted[i]);
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    // Current streak: walk back from today (or yesterday if today is empty).
    var cursor = today;
    if (!activeDays.contains(_key(today))) {
      cursor = today.subtract(const Duration(days: 1));
      if (!activeDays.contains(_key(cursor))) return _Streaks(0, longest);
    }
    var current = 0;
    while (activeDays.contains(_key(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return _Streaks(current, longest);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Small holder for the streak pair (records aren't available on this SDK).
class _Streaks {
  final int current;
  final int longest;
  const _Streaks(this.current, this.longest);
}
