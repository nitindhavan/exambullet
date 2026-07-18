import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/question_model.dart';
import 'package:percent/models/test_model.dart';
import 'package:percent/models/test_result_model.dart';

/// Persists completed test attempts to `testResults/{uid}` and streams them back
/// for the analytics dashboard. Aggregation (trends, topic strengths) is done on
/// the client in [TestAnalytics]. Mirrors the FocusService pattern.
class TestResultService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _ref {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('testResults').child(uid);
  }

  /// Builds a [TestResult] from the raw attempt and saves it. Returns the saved
  /// result (with its generated id), or null if not signed in.
  static Future<TestResult?> saveAttempt({
    required TestModel test,
    required String examId,
    required String paperId,
    required List<Question> questions,
    required List<int> selection, // chosen option per question, -1 = skipped
    required int elapsedSec,
  }) async {
    final ref = _ref;
    if (ref == null) return null;

    double obtained = 0, total = 0;
    int correct = 0, wrong = 0, skipped = 0;
    final topics = <String, TopicStat>{};

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final sel = i < selection.length ? selection[i] : -1;
      total += q.marks;
      final negDeduct =
          q.negativeMarks >= 0 ? q.negativeMarks : test.negativeMarks;

      int c = 0, w = 0, s = 0;
      if (sel == -1) {
        skipped++;
        s = 1;
      } else if (sel == q.answer) {
        correct++;
        obtained += q.marks;
        c = 1;
      } else {
        wrong++;
        if (negDeduct > 0) obtained -= negDeduct;
        w = 1;
      }

      final topic = q.topic.trim().isEmpty ? 'General' : q.topic.trim();
      topics[topic] = (topics[topic] ?? const TopicStat()) +
          TopicStat(correct: c, wrong: w, skipped: s);
    }

    final attempted = correct + wrong;
    final now = DateTime.now();
    final pushRef = ref.push();
    final result = TestResult(
      id: pushRef.key!,
      examId: examId,
      testId: test.id,
      testName: test.name,
      paperId: paperId,
      takenAt: now.millisecondsSinceEpoch,
      obtained: obtained,
      total: total,
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      questionCount: questions.length,
      elapsedSec: elapsedSec,
      accuracy: attempted > 0 ? correct / attempted : 0,
      day: _dayKey(now),
      topics: topics,
    );

    await pushRef.set(result.toMap());
    return result;
  }

  /// All of the current user's attempts, newest first.
  static Stream<List<TestResult>> resultsStream() {
    final ref = _ref;
    if (ref == null) return Stream.value(const []);
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <TestResult>[];
      final raw = value as Map;
      final list = <TestResult>[];
      raw.forEach((key, v) {
        if (v is Map) list.add(TestResult.fromMap(v, key.toString()));
      });
      list.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      return list;
    });
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
