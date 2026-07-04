/// A completed focus (study) session for one exam.
///
/// Stored at `focusSessions/{uid}/{sessionId}`. All aggregation (streak,
/// per-day heatmap, per-exam totals) is derived from these on the client.
class FocusSession {
  final String id;
  final String examId;
  final String examName;
  final int startedAt; // millisecondsSinceEpoch
  final int durationSec;
  final String day; // local "YYYY-MM-DD" — the calendar/streak bucket

  FocusSession({
    required this.id,
    required this.examId,
    required this.examName,
    required this.startedAt,
    required this.durationSec,
    required this.day,
  });

  FocusSession.fromMap(Map<dynamic, dynamic> map, String key)
      : id = map['id'] ?? key,
        examId = map['examId'] ?? '',
        examName = map['examName'] ?? '',
        startedAt = (map['startedAt'] as num?)?.toInt() ?? 0,
        durationSec = (map['durationSec'] as num?)?.toInt() ?? 0,
        day = map['day'] ?? '';

  Map<String, Object?> toMap() => {
        'id': id,
        'examId': examId,
        'examName': examName,
        'startedAt': startedAt,
        'durationSec': durationSec,
        'day': day,
      };
}

/// The in-flight timer state, stored at `focusActive/{uid}` while a session is
/// running. Elapsed time is always computed as `now - startedAt` (wall-clock),
/// so it stays correct across app minimise / kill / reopen.
class ActiveFocus {
  final String examId;
  final String examName;
  final int startedAt; // millisecondsSinceEpoch

  ActiveFocus({
    required this.examId,
    required this.examName,
    required this.startedAt,
  });

  ActiveFocus.fromMap(Map<dynamic, dynamic> map)
      : examId = map['examId'] ?? '',
        examName = map['examName'] ?? '',
        startedAt = (map['startedAt'] as num?)?.toInt() ?? 0;

  Map<String, Object?> toMap() => {
        'examId': examId,
        'examName': examName,
        'startedAt': startedAt,
      };
}
