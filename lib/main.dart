import 'package:flutter/services.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/utils/url_params.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Startup error: $e');
    debugPrint('$st');
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
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xffF6F2FF),
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          color: Color(0xff3D1975),
          toolbarHeight: 70,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xff3D1975),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      home: const Splash(),
    );
  }
}
