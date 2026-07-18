import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';

/// One-time feature walkthrough shown to first-time users (see [Onboarding.seen]
/// gating in Splash). Each page shows a stylised product mock so it reads as a
/// real tour, not a generic icon+text template. Hands off to [onDone] at the end.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key, required this.onDone}) : super(key: key);
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Mock { test, progress, notes, news }

class _Slide {
  const _Slide(this.tag, this.title, this.subtitle, this.accent, this.mock);
  final String tag;
  final String title;
  final String subtitle;
  final Color accent;
  final _Mock mock;
}

const _slides = <_Slide>[
  _Slide('MOCK TESTS', 'Practice like the real exam',
      'Full-length tests with timers, detailed solutions and instant scoring.',
      Color(0xff4F46E5), _Mock.test),
  _Slide('PROGRESS', 'Watch yourself improve',
      'Track scores, accuracy and weak topics that get stronger every test.',
      Color(0xff0EA5E9), _Mock.progress),
  _Slide('NOTES & PRACTICE', 'Everything to prepare',
      'Curated notes and topic-wise practice questions for each exam.',
      Color(0xff10B981), _Mock.notes),
  _Slide('STAY READY', 'Never miss an update',
      'Latest exam news, alerts and a planner to keep you on schedule.',
      Color(0xffF59E0B), _Mock.news),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _slides[_page].accent;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkSurface,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            // Animated tinted backdrop reacting to the current slide's accent.
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.14),
                    AppTheme.surface,
                    AppTheme.surface,
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            // Decorative blobs.
            Positioned(
                top: -70, right: -50, child: _blob(200, accent, 0.16)),
            Positioned(
                top: 120, left: -60, child: _blob(150, accent, 0.10)),

            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLast ? null : widget.onDone,
                          child: Text('Skip',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? accent : AppTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: accent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLast ? 'Get Started' : 'Next',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                                _isLast
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      );
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Floating product mock.
          _MockPreview(slide: slide),
          const Spacer(flex: 2),
          // Little accent tag.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(slide.tag,
                style: GoogleFonts.inter(
                    color: slide.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

/// A stylised mini mock of the relevant feature, floating in a soft card.
class _MockPreview extends StatelessWidget {
  const _MockPreview({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: _body(),
    );
  }

  Widget _body() {
    switch (slide.mock) {
      case _Mock.test:
        return _testMock();
      case _Mock.progress:
        return _progressMock();
      case _Mock.notes:
        return _notesMock();
      case _Mock.news:
        return _newsMock();
    }
  }

  // ── Mock: a timed test question card ─────────────────────────────────────
  Widget _testMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _chip('Q 12/50', slide.accent),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.timer_rounded, size: 13, color: slide.accent),
                const SizedBox(width: 4),
                Text('28:14',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: slide.accent)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _line(1.0),
        const SizedBox(height: 7),
        _line(0.7),
        const SizedBox(height: 16),
        _option('A', false),
        _option('B', true),
        _option('C', false),
      ],
    );
  }

  Widget _option(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? slide.accent.withValues(alpha: 0.10) : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? slide.accent : AppTheme.borderLight,
            width: selected ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? slide.accent : Colors.transparent,
            border: Border.all(
                color: selected ? slide.accent : AppTheme.border, width: 1.5),
          ),
          child: selected
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: _line(selected ? 0.5 : 0.65)),
      ]),
    );
  }

  // ── Mock: a progress dashboard ───────────────────────────────────────────
  Widget _progressMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _stat('82%', 'Accuracy', slide.accent),
          const SizedBox(width: 10),
          _stat('+14', 'This week', const Color(0xff10B981)),
        ]),
        const SizedBox(height: 16),
        Text('Score trend',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(0.35), _bar(0.55), _bar(0.45), _bar(0.7), _bar(0.6), _bar(0.9),
          ],
        ),
      ],
    );
  }

  Widget _stat(String value, String label, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w900, color: c)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _bar(double h) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 60 * h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [slide.accent, slide.accent.withValues(alpha: 0.5)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      );

  // ── Mock: a notes list ───────────────────────────────────────────────────
  Widget _notesMock() {
    return Column(
      children: [
        _noteRow(Icons.calculate_rounded, 0.8),
        _noteRow(Icons.science_rounded, 0.6),
        _noteRow(Icons.public_rounded, 0.7),
        _noteRow(Icons.history_edu_rounded, 0.5),
      ],
    );
  }

  Widget _noteRow(IconData icon, double w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: slide.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_line(w), const SizedBox(height: 6), _line(w * 0.6)],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            size: 18, color: AppTheme.border),
      ]),
    );
  }

  // ── Mock: a news feed ────────────────────────────────────────────────────
  Widget _newsMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xffEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text('NEW',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xffEF4444))),
          ),
          const SizedBox(width: 8),
          Expanded(child: _line(0.6)),
        ]),
        const SizedBox(height: 14),
        _newsItem(Icons.campaign_rounded, 0.9),
        _newsItem(Icons.event_available_rounded, 0.7),
        _newsItem(Icons.notifications_active_rounded, 0.8),
      ],
    );
  }

  Widget _newsItem(IconData icon, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: slide.accent),
        const SizedBox(width: 10),
        Expanded(child: _line(w)),
      ]),
    );
  }

  // ── Shared primitives ────────────────────────────────────────────────────
  Widget _line(double widthFactor) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: 9,
          decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(5)),
        ),
      );

  Widget _chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w800, color: c)),
      );
}
