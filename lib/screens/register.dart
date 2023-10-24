import 'package:exambullet/screens/verify.dart';
import 'package:exambullet/widgets/button.dart';
import 'package:exambullet/widgets/heading.dart';
import 'package:exambullet/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/User.dart';
import 'home.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  var nameController = TextEditingController();
  var visible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(heading: 'Whats your name'),
          InputField(
            controller: nameController,
            hint: 'Enter your name',
          ),
          Button(
              onPressed: () async {
                setState(() {
                  visible=true;
                });
                UserModel model=UserModel(nameController.text, FirebaseAuth.instance.currentUser!.phoneNumber!, FirebaseAuth.instance.currentUser!.uid, []);
                FirebaseDatabase.instance.ref('users').child(model.uid).set(model.toMap()).then((value){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Home(user: model)));
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
