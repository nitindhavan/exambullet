import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google sign-in, working on both web and native, and correctly linking an
/// anonymous guest account when one exists (so their goals/progress carry over).
///
/// Returns the signed-in [User] on success, or null if the user cancelled.
/// Throws [FirebaseAuthException] on real failures for the caller to surface.
class GoogleAuth {
  GoogleAuth._();

  static Future<User?> signIn() async {
    final anon = FirebaseAuth.instance.currentUser;
    final isAnon = anon?.isAnonymous ?? false;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      if (isAnon) {
        try {
          final cred = await anon!.linkWithPopup(provider);
          return cred.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            final cred = await FirebaseAuth.instance.signInWithPopup(provider);
            return cred.user;
          }
          rethrow;
        }
      }
      final cred = await FirebaseAuth.instance.signInWithPopup(provider);
      return cred.user;
    }

    // Native (Android): interactive Google account picker.
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    if (isAnon) {
      try {
        final cred = await anon!.linkWithCredential(credential);
        return cred.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final cred =
              await FirebaseAuth.instance.signInWithCredential(credential);
          return cred.user;
        }
        rethrow;
      }
    }
    final cred = await FirebaseAuth.instance.signInWithCredential(credential);
    return cred.user;
  }
}
