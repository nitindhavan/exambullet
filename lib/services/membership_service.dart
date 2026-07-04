import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/membership_model.dart';

/// Central access point for the single app-wide membership.
///
/// The app moved from per-exam memberships (`memberships/{examId}/{uid}`) to one
/// app-wide membership stored at `appMemberships/{uid}`. A single active,
/// non-expired record unlocks all exams. All gating should go through here so the
/// logic isn't duplicated across screens.
class MembershipService {
  MembershipService._();

  static DatabaseReference _ref(String uid) =>
      FirebaseDatabase.instance.ref('appMemberships').child(uid);

  /// True when [raw] is an active, non-expired app membership.
  static bool _grantsAccess(Object? raw) {
    if (raw is Map) {
      if (raw['isActive'] == false) return false;
      final exp = raw['expiryDate'];
      if (exp is String) {
        final parsed = DateTime.tryParse(exp);
        if (parsed != null && DateTime.now().isAfter(parsed)) return false;
      }
      return true;
    }
    // A non-map truthy value (legacy `true`) counts as access.
    return raw != null;
  }

  /// Live stream of whether the current user has app-wide access.
  /// Emits `false` for signed-out users.
  static Stream<bool> hasAccessStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _ref(uid).onValue.map(
        (event) => event.snapshot.exists && _grantsAccess(event.snapshot.value));
  }

  /// One-shot check of app-wide access for the current user.
  static Future<bool> hasAccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _ref(uid).once();
    return snap.snapshot.exists && _grantsAccess(snap.snapshot.value);
  }

  /// Reads the current user's raw app membership, or null.
  static Future<MembershipModel?> current() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _ref(uid).once();
    if (!snap.snapshot.exists) return null;
    final raw = snap.snapshot.value;
    if (raw is Map) return MembershipModel.fromMap(raw);
    return null;
  }

  /// Writes/activates the app-wide membership for [uid].
  static Future<void> activate(String uid,
      {required String paymentId, String? expiryDate}) async {
    await _ref(uid).set(MembershipModel(
      uid,
      DateTime.now().toIso8601String(),
      paymentId: paymentId,
      expiryDate: expiryDate,
    ).toMap());
  }
}
