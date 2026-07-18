/// A single completed test attempt, persisted at `testResults/{uid}/{pushId}`.
///
/// Stores enough to power the analytics dashboard without re-reading questions:
/// aggregate counts, score, elapsed time, timestamp, and a per-topic correctness
/// breakdown (so weak/strong topics can be computed by summing across attempts).
class TestResult {
  final String id;
  final String examId;
  final String testId;
  final String testName;
  final String paperId;
  final int takenAt; // epoch ms
  final double obtained; // marks after negative marking (may be fractional)
  final double total; // total marks available (may be fractional)
  final int correct;
  final int wrong;
  final int skipped;
  final int questionCount;
  final int elapsedSec;
  final double accuracy; // correct / attempted (0..1)
  final String day; // YYYY-MM-DD, for grouping
  /// topic -> {correct, wrong, skipped}
  final Map<String, TopicStat> topics;

  TestResult({
    required this.id,
    required this.examId,
    required this.testId,
    required this.testName,
    required this.paperId,
    required this.takenAt,
    required this.obtained,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.questionCount,
    required this.elapsedSec,
    required this.accuracy,
    required this.day,
    required this.topics,
  });

  Map<String, Object?> toMap() => {
        'examId': examId,
        'testId': testId,
        'testName': testName,
        'paperId': paperId,
        'takenAt': takenAt,
        'obtained': obtained,
        'total': total,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
        'questionCount': questionCount,
        'elapsedSec': elapsedSec,
        'accuracy': accuracy,
        'day': day,
        'topics': topics.map((k, v) => MapEntry(k, v.toMap())),
      };

  factory TestResult.fromMap(Map<dynamic, dynamic> m, String id) {
    final rawTopics = m['topics'];
    final topics = <String, TopicStat>{};
    if (rawTopics is Map) {
      rawTopics.forEach((k, v) {
        if (v is Map) topics[k.toString()] = TopicStat.fromMap(v);
      });
    }
    return TestResult(
      id: id,
      examId: (m['examId'] ?? '').toString(),
      testId: (m['testId'] ?? '').toString(),
      testName: (m['testName'] ?? '').toString(),
      paperId: (m['paperId'] ?? '').toString(),
      takenAt: (m['takenAt'] as num?)?.toInt() ?? 0,
      obtained: (m['obtained'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      correct: (m['correct'] as num?)?.toInt() ?? 0,
      wrong: (m['wrong'] as num?)?.toInt() ?? 0,
      skipped: (m['skipped'] as num?)?.toInt() ?? 0,
      questionCount: (m['questionCount'] as num?)?.toInt() ?? 0,
      elapsedSec: (m['elapsedSec'] as num?)?.toInt() ?? 0,
      accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0,
      day: (m['day'] ?? '').toString(),
      topics: topics,
    );
  }

  int get attempted => correct + wrong;
  double get scorePct => total > 0 ? obtained.clamp(0, total) / total : 0;
}

class TopicStat {
  final int correct;
  final int wrong;
  final int skipped;

  const TopicStat({this.correct = 0, this.wrong = 0, this.skipped = 0});

  int get attempted => correct + wrong;
  int get total => correct + wrong + skipped;
  double get accuracy => attempted > 0 ? correct / attempted : 0;

  Map<String, Object?> toMap() =>
      {'correct': correct, 'wrong': wrong, 'skipped': skipped};

  factory TopicStat.fromMap(Map<dynamic, dynamic> m) => TopicStat(
        correct: (m['correct'] as num?)?.toInt() ?? 0,
        wrong: (m['wrong'] as num?)?.toInt() ?? 0,
        skipped: (m['skipped'] as num?)?.toInt() ?? 0,
      );

  TopicStat operator +(TopicStat o) => TopicStat(
        correct: correct + o.correct,
        wrong: wrong + o.wrong,
        skipped: skipped + o.skipped,
      );
}
