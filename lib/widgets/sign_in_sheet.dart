import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/screens/phone_auth_screen.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Bottom-sheet sign-in prompt. Phone OTP only (matches the main SignIn screen).
///
/// It doesn't sign the user in itself — it opens [PhoneAuthScreen], which handles
/// OTP, links to an anonymous guest account when present (preserving their data),
/// and routes on to Splash/Home. So this sheet just explains why and launches it.
Future<void> showSignInSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SignInSheet(),
  );
}

class _SignInSheet extends StatelessWidget {
  const _SignInSheet();

  void _continueWithPhone(BuildContext context) {
    Navigator.pop(context); // close the sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _continueWithPhone(context),
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
          const SizedBox(height: 12),
          const LegalConsentText(fontSize: 11),
        ],
      ),
    );
  }
}
