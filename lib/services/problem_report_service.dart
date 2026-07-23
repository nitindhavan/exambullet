import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/problem_report_model.dart';

/// Submits user-reported problems (about a question, paper, or test) to a flat
/// top-level `problemReports` node so the admin app can review them. Mirrors the
/// TestResultService write pattern, but writes flat (not per-uid) since these
/// are admin-facing, not user-facing.
class ProblemReportService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Best-effort reporter name: reads `users/{uid}/name`. Falls back to '' so a
  /// missing name never blocks submitting a report.
  static Future<String> _reporterName(String uid) async {
    try {
      final snap =
          await FirebaseDatabase.instance.ref('users/$uid/name').once();
      return (snap.snapshot.value ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  /// Writes a report and returns it (with generated id), or null if the write
  /// fails / nobody is signed in.
  static Future<ProblemReport?> submit({
    required String type, // 'question' | 'paper' | 'test'
    required String reason,
    String note = '',
    required String examId,
    String testId = '',
    String paperId = '',
    String questionId = '',
    String questionText = '',
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final name = await _reporterName(uid);
      final pushRef = FirebaseDatabase.instance.ref('problemReports').push();
      final report = ProblemReport(
        id: pushRef.key!,
        type: type,
        reason: reason,
        note: note,
        reporterUid: uid,
        reporterName: name,
        examId: examId,
        testId: testId,
        paperId: paperId,
        questionId: questionId,
        questionText: questionText,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: 'open',
      );
      await pushRef.set(report.toMap());
      return report;
    } catch (_) {
      return null;
    }
  }
}
