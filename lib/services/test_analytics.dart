import 'package:percent/models/test_result_model.dart';

/// Client-side aggregation over a user's [TestResult] history for the analytics
/// dashboard. Pure computation — no I/O. Mirrors the FocusStats approach.
class TestAnalytics {
  TestAnalytics(this.results);

  /// Newest-first list of attempts (as returned by TestResultService).
  final List<TestResult> results;

  bool get isEmpty => results.isEmpty;
  int get testsTaken => results.length;

  int get totalQuestions =>
      results.fold(0, (s, r) => s + r.questionCount);
  int get totalCorrect => results.fold(0, (s, r) => s + r.correct);
  int get totalWrong => results.fold(0, (s, r) => s + r.wrong);
  int get totalSkipped => results.fold(0, (s, r) => s + r.skipped);

  /// Overall accuracy across all attempts (correct / attempted).
  double get overallAccuracy {
    final attempted = totalCorrect + totalWrong;
    return attempted > 0 ? totalCorrect / attempted : 0;
  }

  /// Average score percentage across attempts.
  double get avgScorePct {
    if (results.isEmpty) return 0;
    final sum = results.fold<double>(0, (s, r) => s + r.scorePct);
    return sum / results.length;
  }

  /// Best single-attempt score percentage.
  double get bestScorePct {
    if (results.isEmpty) return 0;
    return results.map((r) => r.scorePct).reduce((a, b) => a > b ? a : b);
  }

  /// Total time spent across all attempts, in seconds.
  int get totalTimeSec => results.fold(0, (s, r) => s + r.elapsedSec);

  /// Average time per question across all attempts, in seconds (0 if none).
  double get avgSecPerQuestion {
    final answered = totalCorrect + totalWrong + totalSkipped;
    return answered > 0 ? totalTimeSec / answered : 0;
  }

  /// Score-percentage trend, OLDEST first (for a left-to-right chart).
  List<TrendPoint> get scoreTrend {
    final list = results
        .map((r) => TrendPoint(takenAt: r.takenAt, pct: r.scorePct))
        .toList()
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    return list;
  }

  /// Per-topic aggregate across all attempts, as a list sorted by accuracy asc
  /// (weakest first). Only topics with at least one attempted question.
  List<TopicPerformance> get topicPerformance {
    final merged = <String, TopicStat>{};
    for (final r in results) {
      r.topics.forEach((topic, stat) {
        merged[topic] = (merged[topic] ?? const TopicStat()) + stat;
      });
    }
    final list = merged.entries
        .where((e) => e.value.attempted > 0)
        .map((e) => TopicPerformance(topic: e.key, stat: e.value))
        .toList()
      ..sort((a, b) => a.stat.accuracy.compareTo(b.stat.accuracy));
    return list;
  }

  /// Weakest topics (lowest accuracy first), up to [n].
  List<TopicPerformance> weakestTopics([int n = 5]) =>
      topicPerformance.take(n).toList();

  /// Strongest topics (highest accuracy first), up to [n].
  List<TopicPerformance> strongestTopics([int n = 5]) =>
      topicPerformance.reversed.take(n).toList();

  /// Distinct days on which at least one test was taken.
  Set<String> get activeDays => results.map((r) => r.day).toSet();
}

class TopicPerformance {
  TopicPerformance({required this.topic, required this.stat});
  final String topic;
  final TopicStat stat;
}

class TrendPoint {
  TrendPoint({required this.takenAt, required this.pct});
  final int takenAt;
  final double pct;
}
