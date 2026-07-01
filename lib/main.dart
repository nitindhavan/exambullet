import 'package:flutter/services.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App-wide default: transparent status bar with dark icons over our light UI.
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSurface);

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Percent',
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
