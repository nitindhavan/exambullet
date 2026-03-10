import 'package:percent/models/User.dart';
import 'package:percent/screens/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'home.dart';

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
  late Animation<double> _shimmer;

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

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _percentCtrl, curve: Curves.easeInOut),
    );

    _ringCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
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
              .set(model.toMap());
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
            colors: [Color(0xff1A0840), Color(0xff3D1975), Color(0xff6B3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
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
                                          LinearGradient(
                                        colors: const [
                                          Color(0xffE9D5FF),
                                          Colors.white,
                                          Color(0xffC084FC),
                                        ],
                                        stops: [
                                          (_shimmer.value - 0.3)
                                              .clamp(0.0, 1.0),
                                          _shimmer.value.clamp(0.0, 1.0),
                                          (_shimmer.value + 0.3)
                                              .clamp(0.0, 1.0),
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
                      child: Column(
                        children: [
                          const Text(
                            'Percent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your exam prep companion',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
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
        ..color = Colors.white.withOpacity(0.1)
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
          colors: [Color(0xffC084FC), Colors.white],
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
                color: Colors.white.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
