import 'package:percent/models/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/utils/notification_helper.dart';
import 'dart:math';
import 'home.dart';
import 'signin.dart';
import 'update_required_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _percentCtrl;
  late Animation<double> _ring;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _percentRotate;
  late Animation<double> _percentScale;


  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _percentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ring = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.elasticOut),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _percentRotate = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _percentCtrl, curve: Curves.easeInOut),
    );

    _percentScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _percentCtrl, curve: Curves.easeInOut),
    );



    _ringCtrl.forward();
    _navigate();
  }

  bool _isUpdateRequired(String current, String minReq) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minReq.split('.').map(int.parse).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (minParts.length < 3) {
        minParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minParts[i]) return true;
        if (currentParts[i] > minParts[i]) return false;
      }
    } catch (e) {
      return current != minReq;
    }
    return false;
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // ── Version Check ──────────────────────────────────────
    try {
      final appSettingsSnap = await FirebaseDatabase.instance.ref('appSettings').get();
      if (!mounted) return;
      if (appSettingsSnap.exists && appSettingsSnap.value != null) {
        final settings = appSettingsSnap.value as Map;
        final minVersion = settings['minVersion'] as String? ?? '1.0.0';
        final updateUrl = settings['updateUrl'] as String? ?? '';

        final packageInfo = await PackageInfo.fromPlatform().timeout(
          const Duration(seconds: 3),
          onTimeout: () => PackageInfo(
            appName: 'Percent',
            packageName: 'com.example.percent',
            version: '1.0.0',
            buildNumber: '1',
          ),
        );
        final currentVersion = packageInfo.version;

        if (_isUpdateRequired(currentVersion, minVersion)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateRequiredScreen(updateUrl: updateUrl),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to check app update: $e');
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SignIn()));
    } else {
      FirebaseDatabase.instance
          .ref('users')
          .child(currentUser.uid)
          .once()
          .then((value) {
        if (!mounted) return;
        if (value.snapshot.exists && value.snapshot.value != null) {
          final userModel = UserModel.fromMap(value.snapshot.value as Map);
          NotificationHelper.saveToken(currentUser.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Home(user: userModel)),
          );
        } else {
          final model = UserModel(
            currentUser.displayName ?? 'User',
            currentUser.phoneNumber ?? currentUser.email ?? '',
            currentUser.uid,
            [],
          );
          FirebaseDatabase.instance
              .ref('users')
              .child(model.uid)
              .set(model.toMap())
              .then((_) => NotificationHelper.saveToken(model.uid));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Home(user: model)),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_ringCtrl, _percentCtrl]),
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: _RingPainter(progress: _ring.value),
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: _percentRotate.value,
                                  child: Transform.scale(
                                    scale: _percentScale.value,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          AppTheme.primary,
                                          AppTheme.secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: const Text(
                                        '%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: const Column(
                        children: [
                          Text(
                            'Percent',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your exam prep companion',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _textFade,
                    child: _LoadingDots(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: AppTheme.primaryGradient,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (sin(t * pi)).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
