import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:percent/models/focus_session_model.dart';

/// Focus (study-time) tracking.
///
/// A running session lives at `focusActive/{uid}` as a start timestamp, so the
/// elapsed time is always computed wall-clock (`now - startedAt`) and stays
/// correct across app minimise / kill / reopen. Completed sessions are appended
/// to `focusSessions/{uid}`. All streak / heatmap / insight aggregation is done
/// on the client in [FocusStats].
class FocusService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  /// A single session is capped so a forgotten timer can't log absurd time.
  static const int maxSessionSec = 6 * 60 * 60; // 6 hours

  static const int _ongoingNotifId = 424242;
  static const AndroidNotificationChannel _focusChannel =
      AndroidNotificationChannel(
    'focus_channel',
    'Focus Timer',
    description: 'Shows an ongoing notification while a focus session is active',
    importance: Importance.low, // silent, no heads-up
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _activeRef {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('focusActive').child(uid);
  }

  static DatabaseReference? get _sessionsRef {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('focusSessions').child(uid);
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  static Future<void> _ensureChannel() async {
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_focusChannel);
  }

  // ── Live active-session stream ──────────────────────────────────────────────

  /// Emits the currently running session, or null when idle. Applies the
  /// auto-cap: if a session has been running longer than [maxSessionSec] (e.g.
  /// the user forgot to stop it overnight), it is auto-finalised on read.
  static Stream<ActiveFocus?> activeStream() {
    final ref = _activeRef;
    if (ref == null) return Stream.value(null);
    return ref.onValue.asyncMap((event) async {
      final value = event.snapshot.value;
      if (value == null) return null;
      final active = ActiveFocus.fromMap(value as Map);
      final elapsedSec =
          (DateTime.now().millisecondsSinceEpoch - active.startedAt) ~/ 1000;
      if (elapsedSec >= maxSessionSec) {
        // Forgotten timer — save a capped session and clear it.
        await _finalise(active, maxSessionSec);
        return null;
      }
      return active;
    });
  }

  // ── Start / Stop ────────────────────────────────────────────────────────────

  static Future<void> start(String examId, String examName) async {
    final ref = _activeRef;
    if (ref == null) return;
    final active = ActiveFocus(
      examId: examId,
      examName: examName,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(active.toMap());
    await _showOngoing(examName);
  }

  /// Stops the running session and saves it (if at least 10s elapsed — shorter
  /// taps are treated as accidental and discarded). Returns the saved duration
  /// in seconds, or 0 if nothing was saved.
  static Future<int> stop(ActiveFocus active) async {
    final elapsedSec =
        (DateTime.now().millisecondsSinceEpoch - active.startedAt) ~/ 1000;
    final capped = elapsedSec.clamp(0, maxSessionSec);
    await _cancelOngoing();
    if (capped < 10) {
      await _activeRef?.remove();
      return 0;
    }
    await _finalise(active, capped);
    return capped;
  }

  /// Cancels the running session without saving it.
  static Future<void> discard() async {
    await _cancelOngoing();
    await _activeRef?.remove();
  }

  static Future<void> _finalise(ActiveFocus active, int durationSec) async {
    final sessions = _sessionsRef;
    if (sessions == null) return;
    final ref = sessions.push();
    final id = ref.key!;
    final started = DateTime.fromMillisecondsSinceEpoch(active.startedAt);
    final session = FocusSession(
      id: id,
      examId: active.examId,
      examName: active.examName,
      startedAt: active.startedAt,
      durationSec: durationSec,
      day: _dayKey(started),
    );
    // Write the session and clear the active marker together.
    await ref.set(session.toMap());
    await _activeRef?.remove();
  }

  // ── Sessions stream (for stats views) ───────────────────────────────────────

  static Stream<List<FocusSession>> sessionsStream() {
    final ref = _sessionsRef;
    if (ref == null) return Stream.value(const []);
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <FocusSession>[];
      final raw = value as Map;
      final list = <FocusSession>[];
      raw.forEach((key, v) {
        list.add(FocusSession.fromMap(v as Map, key as String));
      });
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt)); // newest first
      return list;
    });
  }

  // ── Ongoing notification ────────────────────────────────────────────────────

  static Future<void> _showOngoing(String examName) async {
    try {
      await _ensureChannel();
      await _notif.show(
        _ongoingNotifId,
        'Focus session running',
        'Studying $examName · tap the app to stop',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _focusChannel.id,
            _focusChannel.name,
            channelDescription: _focusChannel.description,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true, // can't be swiped away
            autoCancel: false,
            showWhen: true,
            usesChronometer: true, // live-ticking timer in the notification
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (e) {
      debugPrint('focus ongoing notif failed: $e');
    }
  }

  static Future<void> _cancelOngoing() async {
    try {
      await _notif.cancel(_ongoingNotifId);
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
