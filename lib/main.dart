import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/utils/notification_helper.dart';
import 'package:percent/services/presence_service.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/services/funnel_service.dart';
import 'package:percent/services/web_back_handler.dart';
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

  // Push notifications rely on flutter_local_notifications + FCM, which are not
  // supported (and throw) inside a plain web build. Skip the whole block on web
  // so it can never white-screen the app; native keeps full behaviour. Wrapped
  // in try/catch as a belt-and-braces guard against any startup throw.
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationHelper.init();
    } catch (e, st) {
      debugPrint('Notification init skipped/failed: $e');
      debugPrint('$st');
    }
  }

  // Register realtime presence so the admin can see live active usage — this
  // runs before auth, so logged-out visitors are counted too. Fire-and-forget:
  // it must never block or fail app startup.
  try {
    PresenceService.instance.start();
  } catch (e) {
    debugPrint('Presence start failed: $e');
  }

  // Enable Firebase Analytics collection. Fire-and-forget so it never blocks
  // startup (and never throws through to white-screen the web app).
  try {
    Analytics.instance.init();
  } catch (e) {
    debugPrint('Analytics init failed: $e');
  }

  // Pre-registration funnel: capture platform + source (Instagram etc.) and log
  // the app-open stage so we can see where users drop before registering.
  try {
    await Funnel.instance.start();
    Funnel.instance.appOpen();
  } catch (e) {
    debugPrint('Funnel start failed: $e');
  }

  // On web, bridge the browser Back button to the Flutter Navigator so Back
  // pops in-app screens instead of unloading the page (which, inside Instagram's
  // in-app browser, looks like the browser closing). No-op on native.
  WebBackHandler.instance.install();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Percent',
      // Key lets the web Back handler drive this navigator.
      navigatorKey: WebBackHandler.instance.navigatorKey,
      // Analytics screen_view observer + (web only) the browser-history bridge.
      navigatorObservers: [
        Analytics.instance.observer,
        if (WebBackHandler.instance.observer != null)
          WebBackHandler.instance.observer!,
      ],
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
