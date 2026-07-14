import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/sign_in_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

// User-agent sniffing only makes sense on web; on native we never show the
// "download app" UI (native IS the app). Guarded behind kIsWeb everywhere.
import 'guest_gate_web.dart' if (dart.library.io) 'guest_gate_stub.dart' as ua;

/// Central logic for the web "browse-first, sign-in-later" experience.
///
/// On web we sign guests in anonymously (see splash), so `currentUser` is never
/// null — the guest has a real uid and every screen keeps working. The gate
/// signal is therefore "is the user anonymous?", not "is uid null?".
///
/// Three tiers:
///   - free browse: no gate
///   - soft nudge: dismissible "sign in so your {reason} isn't lost"
///   - hard gate: purchase requires a real (non-anon) account
class GuestGate {
  GuestGate._();

  /// The Google Play listing. Only ever opened when the user explicitly taps
  /// "Download app" — never an automatic redirect.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.moralmosaic.percent';

  /// A guest = a signed-in-but-anonymous user (web), or no user at all.
  static bool get isGuest =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  /// True only on Android web — the one place the "Download app" push belongs.
  /// iOS web and desktop web never see it (no iOS app exists).
  static bool get isAndroidWeb => kIsWeb && ua.isAndroidBrowser;

  /// Opens the Play Store listing (explicit user action only).
  static Future<void> openPlayStore() async {
    final uri = Uri.parse(playStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Soft, dismissible nudge. Returns nothing — the guest may sign in or dismiss
  /// and keep browsing. [reason] fills "so your ___ isn't lost" (e.g. "goal",
  /// "test progress", "results").
  static Future<void> softNudge(BuildContext context,
      {required String reason}) async {
    if (!isGuest) return; // already a real account — nothing to nudge
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _NudgeSheet(reason: reason),
    );
  }

  /// Hard gate for committed actions (purchase). Shows a blocking sheet; returns
  /// true only once the user has a real (non-anonymous) account. Returns false
  /// if they cancel.
  static Future<bool> requireAccount(BuildContext context,
      {required String reason}) async {
    if (!isGuest) return true;
    await showSignInSheet(context);
    // After the sheet closes, re-check: linking/sign-in flips isAnonymous off.
    return !isGuest;
  }

  /// After a guest converts to a real account, their saved name may still be the
  /// placeholder "Guest" (phone sign-in carries no display name). Prompt once for
  /// a real name and save it. No-op if the account already has a proper name.
  static Future<void> promptForNameIfNeeded(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/name');
    final snap = await ref.get();
    final current = (snap.value as String?)?.trim() ?? '';
    // Already has a real name (e.g. from Google) — nothing to ask.
    if (current.isNotEmpty && current.toLowerCase() != 'guest') return;
    if (!context.mounted) return;

    final controller = TextEditingController(
      text: (user.displayName ?? '').trim(),
    );
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _NamePromptSheet(controller: controller),
      ),
    );
    final chosen = (name ?? '').trim();
    if (chosen.isNotEmpty) {
      await ref.set(chosen);
    }
  }
}

/// One-time "what should we call you?" prompt shown after a guest signs in.
class _NamePromptSheet extends StatefulWidget {
  const _NamePromptSheet({required this.controller});
  final TextEditingController controller;

  @override
  State<_NamePromptSheet> createState() => _NamePromptSheetState();
}

class _NamePromptSheetState extends State<_NamePromptSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
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
          const Text('Welcome! What should we call you?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('This is how your name appears in the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.pop(context, v),
            decoration: InputDecoration(
              hintText: 'Your name',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, widget.controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft-nudge bottom sheet: offers sign-in, plus (Android web only) a
/// "Download the app" button. "Not now" dismisses and keeps browsing.
class _NudgeSheet extends StatelessWidget {
  const _NudgeSheet({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
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
            child: const Icon(Icons.bookmark_added_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Save your $reason',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Sign in so your $reason is saved to your account and never lost.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showSignInSheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sign in to save',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          // Android web only: offer the native app as an alternative.
          if (GuestGate.isAndroidWeb) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  GuestGate.openPlayStore();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.android_rounded, size: 20),
                label: const Text('Download the app',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
