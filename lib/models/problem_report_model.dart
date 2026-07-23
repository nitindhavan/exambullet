/// A user-submitted problem report, persisted flat at `problemReports/{pushId}`
/// (top-level, not per-user) so the admin app can list every report like it
/// lists `notifications`.
///
/// [type] says what stage the report is about; the relevant id fields
/// (testId/paperId/questionId) are filled in depending on type. [reason] is a
/// short category chosen from a fixed list; [note] is the user's optional
/// free-text detail. [status] drives the admin triage workflow.
class ProblemReport {
  final String id;
  final String type; // 'question' | 'paper' | 'test'
  final String reason; // e.g. 'Wrong answer', 'Typo', 'Other'
  final String note; // optional free text ('' if none)
  final String reporterUid;
  final String reporterName;
  final String examId;
  final String testId;
  final String paperId;
  final String questionId;
  final String questionText; // snapshot, so admin sees it even if data changes
  final int createdAt; // epoch ms
  final String status; // 'open' | 'resolved' | 'dismissed'

  ProblemReport({
    required this.id,
    required this.type,
    required this.reason,
    required this.note,
    required this.reporterUid,
    required this.reporterName,
    required this.examId,
    required this.testId,
    required this.paperId,
    required this.questionId,
    required this.questionText,
    required this.createdAt,
    required this.status,
  });

  Map<String, Object?> toMap() => {
        'type': type,
        'reason': reason,
        'note': note,
        'reporterUid': reporterUid,
        'reporterName': reporterName,
        'examId': examId,
        'testId': testId,
        'paperId': paperId,
        'questionId': questionId,
        'questionText': questionText,
        'createdAt': createdAt,
        'status': status,
      };

  factory ProblemReport.fromMap(Map<dynamic, dynamic> m, String id) =>
      ProblemReport(
        id: id,
        type: (m['type'] ?? '').toString(),
        reason: (m['reason'] ?? '').toString(),
        note: (m['note'] ?? '').toString(),
        reporterUid: (m['reporterUid'] ?? '').toString(),
        reporterName: (m['reporterName'] ?? '').toString(),
        examId: (m['examId'] ?? '').toString(),
        testId: (m['testId'] ?? '').toString(),
        paperId: (m['paperId'] ?? '').toString(),
        questionId: (m['questionId'] ?? '').toString(),
        questionText: (m['questionText'] ?? '').toString(),
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        status: (m['status'] ?? 'open').toString(),
      );
}
