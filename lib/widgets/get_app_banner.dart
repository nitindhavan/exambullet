import 'package:flutter/material.dart';
import 'package:percent/services/guest_gate.dart';
import 'package:percent/utils/theme.dart';

/// Sticky, dismissible "Get the app" banner. Shows ONLY on Android web
/// (GuestGate.isAndroidWeb) — never on iOS web (no iOS app) or in the native
/// app. Tapping "Get app" opens the Play Store; dismissal lasts the session.
class GetAppBanner extends StatefulWidget {
  const GetAppBanner({super.key});

  /// Session-scoped dismissal — resets on a fresh page load, which is fine: the
  /// nudge should reappear for a new visit but not pester within one session.
  static bool _dismissed = false;

  @override
  State<GetAppBanner> createState() => _GetAppBannerState();
}

class _GetAppBannerState extends State<GetAppBanner> {
  @override
  Widget build(BuildContext context) {
    if (!GuestGate.isAndroidWeb || GetAppBanner._dismissed) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.android_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get the Percent app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  Text('Faster, works offline, push reminders',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: GuestGate.openPlayStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Get app',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: () => setState(() => GetAppBanner._dismissed = true),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 20),
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
