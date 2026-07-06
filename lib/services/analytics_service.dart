import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Analytics for the app's key events.
///
/// Firebase Analytics auto-collects `first_open`, `session_start`,
/// `screen_view`, etc. once initialised (no manifest config needed — it uses the
/// existing google-services.json). Here we add the custom conversion events that
/// matter for this product so they show up in the Firebase console / can be used
/// for audiences and (optionally) Google Ads.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Navigator observer to log automatic screen_view events. Add to
  /// MaterialApp(navigatorObservers: [Analytics.instance.observer]).
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);

  /// Enable collection (call once at startup). Also sets a stable flag so
  /// analytics survive app restarts.
  Future<void> init() async {
    try {
      await _fa.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  /// Ties events to the signed-in user (do NOT log PII — the uid is fine).
  Future<void> setUser(String uid) async {
    try {
      await _fa.setUserId(id: uid);
    } catch (e) {
      debugPrint('Analytics setUser failed: $e');
    }
  }

  Future<void> clearUser() async {
    try {
      await _fa.setUserId(id: null);
    } catch (_) {}
  }

  /// New user signed up.
  Future<void> logSignUp({String method = 'google'}) async {
    try {
      await _fa.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp failed: $e');
    }
  }

  /// User signed in.
  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _fa.logLogin(loginMethod: method);
    } catch (_) {}
  }

  /// Membership purchased (revenue in ₹).
  Future<void> logPurchase({
    required double amount,
    String currency = 'INR',
    String? plan,
  }) async {
    try {
      await _fa.logPurchase(
        value: amount,
        currency: currency,
        parameters: {if (plan != null) 'plan': plan},
      );
    } catch (e) {
      debugPrint('Analytics logPurchase failed: $e');
    }
  }

  /// User added an exam as a goal.
  Future<void> logAddGoal(String examId, String examName) async {
    try {
      await _fa.logEvent(name: 'add_goal_exam', parameters: {
        'exam_id': examId,
        'exam_name': examName,
      });
    } catch (_) {}
  }

  /// User started a mock test.
  Future<void> logStartTest(String testId, String examId) async {
    try {
      await _fa.logEvent(name: 'start_test', parameters: {
        'test_id': testId,
        'exam_id': examId,
      });
    } catch (_) {}
  }

  /// User completed a mock test (with their score %).
  Future<void> logCompleteTest({
    required String testId,
    required String examId,
    required int scorePct,
  }) async {
    try {
      await _fa.logEvent(name: 'complete_test', parameters: {
        'test_id': testId,
        'exam_id': examId,
        'score_pct': scorePct,
      });
    } catch (_) {}
  }

  /// Reached the membership/paywall screen (funnel step before purchase).
  Future<void> logViewPaywall() async {
    try {
      await _fa.logEvent(name: 'view_paywall');
    } catch (_) {}
  }
}
