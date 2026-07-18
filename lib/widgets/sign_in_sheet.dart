import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/screens/phone_auth_screen.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/services/google_auth.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Bottom-sheet sign-in prompt. Offers PHONE (primary) and GOOGLE.
///
/// Phone opens [PhoneAuthScreen] (OTP + guest linking). Google signs in inline
/// via [GoogleAuth] (also links an anonymous guest) then routes to Splash, which
/// creates/loads the user record and continues to Home.
Future<void> showSignInSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SignInSheet(),
  );
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet();

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  bool _loading = false;

  void _continueWithPhone() {
    Navigator.pop(context); // close the sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      final wasGuest =
          FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
      final user = await GoogleAuth.signIn();
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return; // cancelled
      }
      Analytics.instance.setUser(user.uid);
      if (wasGuest) Analytics.instance.logSignUp();
      if (!mounted) return;
      // Splash creates/loads users/{uid} and routes to Home.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash()),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            'Access tests, track scores and keep\nyour progress saved to your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Primary: phone.
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _continueWithPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.smartphone_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with phone',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          // Secondary: Google (more providers can slot in here later).
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _loading ? null : _continueWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                          width: 22,
                          height: 22,
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

/// "or continue with" separator between the primary option and the rest.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: AppTheme.borderLight)),
      ],
    );
  }
}
