import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/User.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/screens/home.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/utils/notification_helper.dart';
import 'package:percent/widgets/ui/ui.dart';

Future<void> showSignInSheet(BuildContext context) {
  // Keep a reference to the root navigator before the sheet opens
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SignInSheet(rootNavigator: rootNavigator),
  );
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.rootNavigator});
  final NavigatorState rootNavigator;

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _loading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final snap = await FirebaseDatabase.instance.ref('users/${firebaseUser.uid}').once();
      if (!mounted) return;
      UserModel userModel;
      Analytics.instance.setUser(firebaseUser.uid);
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        userModel = UserModel.fromMap(snap.snapshot.value as Map);
        Analytics.instance.logLogin();
      } else {
        userModel = UserModel(
          firebaseUser.displayName ?? 'User',
          firebaseUser.phoneNumber ?? firebaseUser.email ?? '',
          firebaseUser.uid,
          [],
        );
        await FirebaseDatabase.instance.ref('users/${firebaseUser.uid}').set(userModel.toMap());
        Analytics.instance.logSignUp(); // new user
      }
      NotificationHelper.saveToken(firebaseUser.uid);
      widget.rootNavigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Home(user: userModel)),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.percent, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to continue',
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Access tests, track scores and unlock\nyour full exam prep experience.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white70,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryLight),
                          child: const Icon(Icons.g_mobiledata_rounded,
                              size: 18, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const LegalConsentText(fontSize: 11),
        ],
      ),
    );
  }
}
