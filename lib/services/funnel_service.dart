import 'dart:math';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Pre-registration funnel tracking, written to Realtime Database so we can see
/// exactly where users drop off between an Instagram click and registration.
///
/// Layout: `funnel/{sessionId}` holds one node per session with:
///   - meta: platform, source, startedAt
///   - `{stage}`: server timestamp when that stage was first reached
///
/// One node per session lets us read a user's whole journey and see which stage
/// is the last one they reached (i.e. where they dropped). Stages are logged
/// once per session (idempotent) so refreshes don't inflate counts.
class Funnel {
  Funnel._();
  static final Funnel instance = Funnel._();

  String? _sessionId;
  final Set<String> _logged = {}; // stages already logged this session
  String _platform = 'unknown';
  String _source = 'direct';
  bool _started = false;

  DatabaseReference? get _ref {
    final id = _sessionId;
    if (id == null) return null;
    return FirebaseDatabase.instance.ref('funnel/$id');
  }

  /// Call once at startup (before/around auth). Captures platform + source and
  /// writes the session meta. Safe to call repeatedly.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _sessionId = _generateSessionId();
    _platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    _source = await _detectSource();

    try {
      await _ref?.child('meta').set({
        'platform': _platform,
        'source': _source,
        'startedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Funnel meta write failed: $e');
    }
  }

  /// Detects the acquisition source.
  ///
  /// Web: read utm_source / ref from the URL (an Instagram link's
  /// `?utm_source=instagram` lands right there).
  ///
  /// Android: the app can't see the browser URL, but the Play Install Referrer
  /// API surfaces the `referrer` string that was attached to the Play Store URL
  /// at click time. So if the Instagram redirect points at
  /// `play.google.com/...&referrer=utm_source%3Dinstagram`, we recover
  /// `instagram` here on the very first launch. Falls back to 'app' when there's
  /// no referrer (organic install) or the API is unavailable.
  Future<String> _detectSource() async {
    if (kIsWeb) {
      try {
        final params = Uri.base.queryParameters;
        final utm = params['utm_source'] ?? params['source'] ?? params['ref'];
        if (utm != null && utm.isNotEmpty) return utm.toLowerCase();
        return 'web-direct';
      } catch (_) {
        return 'web-direct';
      }
    }
    // Native: only Android exposes an install referrer.
    if (defaultTargetPlatform != TargetPlatform.android) return 'app';
    try {
      final details = await AndroidPlayInstallReferrer.installReferrer;
      final raw = details.installReferrer; // e.g. "utm_source=instagram&utm_medium=..."
      if (raw == null || raw.isEmpty) return 'app';
      // The referrer is a query-string; parse utm_source / source / ref out of it.
      final params = Uri.splitQueryString(raw);
      final utm = params['utm_source'] ?? params['source'] ?? params['ref'];
      if (utm != null && utm.isNotEmpty) return utm.toLowerCase();
      return 'app';
    } catch (e) {
      debugPrint('Install referrer lookup failed: $e');
      return 'app';
    }
  }

  /// Logs a funnel stage once per session (idempotent). Every stage carries its
  /// own platform+source copy so the admin can group by them without having to
  /// join back to `meta` (and it survives a failed meta write).
  Future<void> log(String stage, {Map<String, Object?>? extra}) async {
    if (_logged.contains(stage)) return;
    _logged.add(stage);
    final ref = _ref;
    if (ref == null) return;
    try {
      await ref.child(stage).set({
        'ts': ServerValue.timestamp,
        'platform': _platform,
        'source': _source,
        if (extra != null) ...extra,
      });
    } catch (e) {
      debugPrint('Funnel log "$stage" failed: $e');
    }
  }

  // ── Named stages (call these at the right points) ───────────────────────────
  Future<void> appOpen() => log('app_open');
  Future<void> signinScreen() => log('signin_screen');
  Future<void> signinStarted({String method = 'google'}) =>
      log('signin_started', extra: {'method': method});
  Future<void> authAttempted({String method = 'google'}) =>
      log('auth_attempted', extra: {'method': method});
  Future<void> authFailed(String reason, {String method = 'google'}) =>
      // Not idempotent-guarded on purpose isn't needed; log() dedupes, but a
      // failure reason is useful — allow re-log with a distinct stage key.
      _ref?.child('auth_failed').set({
        'ts': ServerValue.timestamp,
        'platform': _platform,
        'source': _source,
        'reason': reason.length > 300 ? reason.substring(0, 300) : reason,
        'method': method,
      }) ??
      Future.value();
  Future<void> registered() => log('registered');
  Future<void> homeReached() => log('home_reached');

  String _generateSessionId() {
    final rnd = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = List.generate(6, (_) => rnd.nextInt(36).toRadixString(36)).join();
    return '$ts$salt';
  }
}
