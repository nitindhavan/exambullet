import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent/screens/phone_auth_screen.dart';
import 'package:percent/services/funnel_service.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

const _kFeatures = [
  _Feature(Icons.quiz_outlined, 'Full-length mock tests with detailed analytics'),
  _Feature(Icons.menu_book_rounded, 'Curated notes & practice questions'),
  _Feature(Icons.campaign_rounded, 'Latest exam news & updates'),
];

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  void initState() {
    super.initState();
    Funnel.instance.signinScreen();
  }

  void _signInWithPhone() {
    Funnel.instance.signinStarted(method: 'phone');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: isDesktop
          ? _DesktopLayout(onPhoneSignIn: _signInWithPhone)
          : _MobileLayout(onPhoneSignIn: _signInWithPhone),
    );
  }
}

// ── Desktop: two-column layout ────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.onPhoneSignIn});
  final VoidCallback onPhoneSignIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: gradient branding panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -60, right: -60,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80, left: -40,
                  child: Container(
                    width: 320, height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: const Icon(Icons.percent, color: Colors.white, size: 46),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Percent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ace your exams with\nsmart practice tests',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 20,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),
                        ..._kFeatures.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(f.icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: sign-in card
        Expanded(
          flex: 4,
          child: Container(
            color: AppTheme.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to access your tests, scores\nand memberships.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      AppButton(
                        label: 'Continue with phone',
                        icon: Icons.smartphone_rounded,
                        height: 56,
                        onPressed: onPhoneSignIn,
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: LegalConsentText(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile: original stacked layout ──────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.onPhoneSignIn});
  final VoidCallback onPhoneSignIn;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkSurface,
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.percent, color: Colors.white, size: 52),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Percent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ace your exams with\nsmart practice tests',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to access your tests, scores\nand memberships.',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Continue with phone',
                        icon: Icons.smartphone_rounded,
                        height: 58,
                        onPressed: onPhoneSignIn,
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: LegalConsentText(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _featureChip(Icons.quiz_outlined, 'Mock Tests'),
                          _featureChip(Icons.menu_book_rounded, 'Notes'),
                          _featureChip(Icons.campaign_rounded, 'News'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}
