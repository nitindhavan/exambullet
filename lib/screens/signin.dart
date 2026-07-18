import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent/screens/phone_auth_screen.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/services/funnel_service.dart';
import 'package:percent/services/google_auth.dart';
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

  bool _googleLoading = false;

  void _signInWithPhone() {
    Funnel.instance.signinStarted(method: 'phone');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    Funnel.instance.signinStarted(method: 'google');
    Funnel.instance.authAttempted(method: 'google');
    try {
      final user = await GoogleAuth.signIn();
      if (user == null) {
        if (mounted) setState(() => _googleLoading = false);
        return; // cancelled
      }
      Analytics.instance.setUser(user.uid);
      Funnel.instance.log('auth_success', extra: {'method': 'google'});
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash()),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      Funnel.instance.authFailed('google:$e', method: 'google');
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: isDesktop
          ? _DesktopLayout(
              onPhoneSignIn: _signInWithPhone,
              onGoogleSignIn: _signInWithGoogle,
              googleLoading: _googleLoading)
          : _MobileLayout(
              onPhoneSignIn: _signInWithPhone,
              onGoogleSignIn: _signInWithGoogle,
              googleLoading: _googleLoading),
    );
  }
}

/// Shared "or continue with" + Google button block for the sign-in layouts.
class _GoogleOption extends StatelessWidget {
  const _GoogleOption(
      {required this.onGoogleSignIn, required this.loading});
  final VoidCallback onGoogleSignIn;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Softer, centered divider.
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.border.withValues(alpha: 0.7),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('or',
                  style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.border.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Elevated white Google button with a real multicolour "G".
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: loading ? null : onGoogleSignIn,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1.4),
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _GoogleGPainter()),
                          ),
                          const SizedBox(width: 12),
                          const Text('Continue with Google',
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimal multicolour Google "G" mark drawn with arcs (no asset needed).
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.22;
    final r = (size.width - stroke) / 2;
    final center = rect.center;
    final arc = Rect.fromCircle(center: center, radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four brand-coloured arcs forming the ring.
    p.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(arc, -0.35, 1.2, false, p);
    p.color = const Color(0xFF34A853); // green
    canvas.drawArc(arc, 0.9, 1.15, false, p);
    p.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(arc, 2.1, 1.15, false, p);
    p.color = const Color(0xFFEA4335); // red
    canvas.drawArc(arc, 3.3, 1.6, false, p);

    // The horizontal bar of the "G".
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke / 2,
          r + stroke / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Desktop: two-column layout ────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.onPhoneSignIn,
    required this.onGoogleSignIn,
    required this.googleLoading,
  });
  final VoidCallback onPhoneSignIn;
  final VoidCallback onGoogleSignIn;
  final bool googleLoading;

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
                      _GoogleOption(
                        onGoogleSignIn: onGoogleSignIn,
                        loading: googleLoading,
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
  const _MobileLayout({
    required this.onPhoneSignIn,
    required this.onGoogleSignIn,
    required this.googleLoading,
  });
  final VoidCallback onPhoneSignIn;
  final VoidCallback onGoogleSignIn;
  final bool googleLoading;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkSurface,
      child: Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ── Hero: full-bleed gradient with soft depth ──────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative blurred circles for depth.
                  Positioned(
                    top: -50, right: -40,
                    child: _glowCircle(200, 0.10),
                  ),
                  Positioned(
                    bottom: 10, left: -60,
                    child: _glowCircle(220, 0.08),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with a soft glow ring.
                          Container(
                            width: 92, height: 92,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.percent,
                                color: Colors.white, size: 50),
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Percent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ace your exams with smart practice tests',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 15.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _FeaturePill(Icons.quiz_outlined, 'Mock Tests'),
                              _FeaturePill(Icons.menu_book_rounded, 'Notes'),
                              _FeaturePill(Icons.campaign_rounded, 'News'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sign-in sheet ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
                    offset: Offset(0, -10)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grab handle for a refined "sheet" feel.
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to save your progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Continue with phone',
                      icon: Icons.smartphone_rounded,
                      height: 56,
                      onPressed: onPhoneSignIn,
                    ),
                    const SizedBox(height: 14),
                    _GoogleOption(
                      onGoogleSignIn: onGoogleSignIn,
                      loading: googleLoading,
                    ),
                    const SizedBox(height: 16),
                    const Center(child: LegalConsentText()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _glowCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

/// Compact glass pill used on the gradient branding area (icon + label).
class _FeaturePill extends StatelessWidget {
  const _FeaturePill(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
