import 'package:exambullet/main.dart';
import 'package:exambullet/models/exam.dart';
import 'package:exambullet/models/membership_model.dart';
import 'package:exambullet/screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/button.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:razorpay_web/razorpay_flutter_web.dart';

class MemberShipScreen extends StatefulWidget {
  const MemberShipScreen({Key? key, required this.model}) : super(key: key);

  final String model;
  @override
  State<MemberShipScreen> createState() => _MemberShipScreenState();
}

class _MemberShipScreenState extends State<MemberShipScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Get Membership'),),
      body: Container(
        child: FutureBuilder(builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if(!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Color(0xff3D1975),));

          ExamModel model=ExamModel.fromMap(snapshot.data!.snapshot.value as Map);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32,),
                Text(model.name,style: TextStyle(color: Color(0xff3D1975),fontSize: 32,fontWeight: FontWeight.w900),),
                SizedBox(height: 16,),
                Text('At just'),
                SizedBox(height: 16,),
                Text('₹ 100',style: TextStyle(color: Color(0xff3D1975),fontSize: 32,fontWeight: FontWeight.w900),),
                SizedBox(height: 64,),
                Container(
                  width: double.infinity,
                  child: Card(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("What you will get:",style: TextStyle(fontWeight: FontWeight.bold),),
                          SizedBox(height: 16,),
                          Text("Full Access to app"),
                          SizedBox(height: 16,),
                          Text('All future updates of the app'),
                          SizedBox(height: 16,),
                          Text('No time limit on membership'),
                          SizedBox(height: 16,),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32,),
                Button(
                    onPressed: () async {
                      var options = {
                        //rzp_live_6q8pkMVogLnDAa
                        //rzp_test_waMZtMqYkvyLTm
                        'key': 'rzp_test_waMZtMqYkvyLTm',
                        'amount': 10000,
                        'name': 'Exam Bullet',
                        'description': 'Membership',
                        'auto_capture': 1,
                        'prefill': {
                          'contact': FirebaseAuth.instance.currentUser!.phoneNumber,
                        }
                      };

                      RazorpayFlutterPlugin().startPayment(options).then((value){
                        value['type']==0 ? paymentSuccess() : paymentFailed();
                      });

                    },
                    text: 'Get Membership'),

              ],
            ),
          );
        },future: FirebaseDatabase.instance.ref('exams').child(origin!).once(),),
      ),
    );
  }

  paymentSuccess() {
    MembershipModel model=MembershipModel(widget.model,FirebaseAuth.instance.currentUser!.uid , DateTime.now().toIso8601String());
    FirebaseDatabase.instance.ref('memberships').child(widget.model).child(FirebaseAuth.instance.currentUser!.uid).set(model.toMap()).then((value){
      Navigator.pop(context);
    });
  }

  paymentFailed() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed')));
  }

}
