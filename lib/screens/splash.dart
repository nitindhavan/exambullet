import 'package:exambullet/models/User.dart';
import 'package:exambullet/screens/register.dart';
import 'package:exambullet/screens/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class Splash extends StatelessWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 0)).then((value) {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const SignIn()));
      } else {
        FirebaseDatabase.instance
            .ref('users').child(FirebaseAuth.instance.currentUser!.uid)
            .once()
            .then((value) {
          if (value.snapshot.exists) {
            UserModel userModel =
                UserModel.fromMap(value.snapshot.value as Map);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Home(user: userModel),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Register()),
            );
          }
        });
      }
    });
    return Scaffold(
      backgroundColor: Color(0xffF6F2FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(64.0),
          child: Image.asset('icon.png'),
        ),
      ),
    );
  }
}
