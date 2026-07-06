import 'package:flutter/services.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/utils/notification_helper.dart';
import 'package:percent/services/presence_service.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

// Must be a top-level function (runs in a separate isolate).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM shows the system notification itself when the app is backgrounded;
  // no extra work needed here.
  debugPrint('Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App-wide default: transparent status bar with dark icons over our light UI.
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSurface);

  // Lock the app to portrait orientation (no landscape / rotation).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    Firebase.app();
  } catch (e) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (err, st) {
      debugPrint('Startup error: $err');
      debugPrint('$st');
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationHelper.init();

  // Register realtime presence so the admin can see live active usage — this
  // runs before auth, so logged-out visitors are counted too. Fire-and-forget:
  // it must never block or fail app startup.
  PresenceService.instance.start();

  // Enable Firebase Analytics collection (uses google-services.json; no manifest
  // config needed). Fire-and-forget so it never blocks startup.
  Analytics.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Percent',
      // Logs a screen_view event on every route push/pop.
      navigatorObservers: [Analytics.instance.observer],
      theme: ThemeData(
        primaryColor: AppTheme.primary,
        scaffoldBackgroundColor: AppTheme.background,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          toolbarHeight: 70,
          elevation: 0,
          systemOverlayStyle: AppTheme.lightSurface,
        ),
      ),
      home: const Splash(),
    );
  }
}
