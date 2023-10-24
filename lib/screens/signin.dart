import 'package:exambullet/screens/verify.dart';
import 'package:exambullet/widgets/button.dart';
import 'package:exambullet/widgets/heading.dart';
import 'package:exambullet/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  var phoneController = TextEditingController();
  var visible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(heading: 'Sign in with phone'),
          InputField(
            controller: phoneController,
            hint: 'Enter phone Number',
          ),
          Button(
              onPressed: () async {
                setState(() {
                  visible=true;
                });
                if(!phoneController.text.contains('+91')) phoneController.text='+91'+phoneController.text;
                ConfirmationResult result=await FirebaseAuth.instance.signInWithPhoneNumber(phoneController.text);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> VerifyOTP(result: result)));
              },
              text: 'Continue'),
          SizedBox(height: 32,),
          if (visible)
            Center(
                child: CircularProgressIndicator(
              color: Color(0xff3D1975),
            )),
        ],
      ),
    );
  }
}
