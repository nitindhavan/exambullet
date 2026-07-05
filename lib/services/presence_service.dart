import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

/// Tracks realtime "who is using the app right now" — including logged-out
/// visitors — using Realtime Database presence.
///
/// How it works:
///  - On app start we register a unique `presence/{sessionId}` node.
///  - We attach `onDisconnect().remove()` so RTDB deletes that node the moment
///    the client disconnects (app closed, network dropped, process killed). This
///    is server-side cleanup, so we never leak stale "active" sessions.
///  - The admin app counts the children of `presence/` to get "N active now".
///
/// This deliberately counts live *sessions*, not installs. Real download
/// numbers come from Play Console; this is for the realtime pulse of usage.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  DatabaseReference? _sessionRef;
  String? _sessionId;
  bool _started = false;

  /// Call once, early in app startup (after Firebase.initializeApp).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _sessionId = _generateSessionId();
    _sessionRef = FirebaseDatabase.instance.ref('presence/$_sessionId');

    WidgetsBinding.instance.addObserver(this);

    // Re-assert presence whenever the socket reconnects, and (re)arm the
    // onDisconnect cleanup — onDisconnect must be re-registered after each
    // reconnect or it won't fire the next time.
    FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value == true;
      if (connected) {
        _writePresence();
      }
    });
  }

  Future<void> _writePresence() async {
    final ref = _sessionRef;
    if (ref == null) return;
    try {
      // onDisconnect first so a disconnect between set() and arming still cleans up.
      await ref.onDisconnect().remove();
      await ref.set({
        'startedAt': ServerValue.timestamp,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Presence write failed: $e');
    }
  }

  /// Manually clear presence (e.g. explicit sign-out or app shutdown).
  Future<void> stop() async {
    try {
      await _sessionRef?.onDisconnect().cancel();
      await _sessionRef?.remove();
    } catch (e) {
      debugPrint('Presence stop failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is foregrounded again, re-assert presence (the socket may
    // have been torn down while backgrounded). When backgrounded we leave the
    // onDisconnect to handle cleanup if the OS kills us.
    if (state == AppLifecycleState.resumed) {
      _writePresence();
    }
  }

  String _generateSessionId() {
    final rnd = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = List.generate(6, (_) => rnd.nextInt(36).toRadixString(36)).join();
    return '$ts$salt';
  }
}
