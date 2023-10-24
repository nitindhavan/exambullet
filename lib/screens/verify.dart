import 'package:exambullet/screens/splash.dart';
import 'package:exambullet/widgets/button.dart';
import 'package:exambullet/widgets/heading.dart';
import 'package:exambullet/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyOTP extends StatefulWidget {
  const VerifyOTP({Key? key,required this.result}) : super(key: key);

  final ConfirmationResult result;
  @override
  State<VerifyOTP> createState() => _VerifyOTPState();
}

class _VerifyOTPState extends State<VerifyOTP> {
  var otpController = TextEditingController();
  var visible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(heading: 'Enter OTP sent to your phone'),
          InputField(
            controller: otpController,
            hint: 'Enter OTP',
          ),
          Button(
              onPressed: () async {
                setState(() {
                  visible=true;
                });
                await widget.result.confirm(otpController.text).then((value){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Splash()));
                });
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
