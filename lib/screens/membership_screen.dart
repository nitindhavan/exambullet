import 'package:exambullet/main.dart';
import 'package:exambullet/models/exam.dart';
import 'package:exambullet/models/membership_model.dart';
import 'package:exambullet/screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter_customui/razorpay_flutter_customui.dart';

import '../widgets/button.dart';

class MemberShipScreen extends StatefulWidget {
  const MemberShipScreen({Key? key, required this.model}) : super(key: key);

  final String model;
  @override
  State<MemberShipScreen> createState() => _MemberShipScreenState();
}

class _MemberShipScreenState extends State<MemberShipScreen> {
  late Razorpay _razorpay;  // ✅ Correct class: Razorpay (not RazorpayFlutterPlugin)

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();  // ✅ Always clear listeners
    super.dispose();
  }

  void _handlePaymentSuccess(Map<dynamic, dynamic> response) {
    paymentSuccess();
  }

  void _handlePaymentError(Map<dynamic, dynamic> response) {
    paymentFailed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Membership')),
      body: FutureBuilder(
        future: FirebaseDatabase.instance.ref('exams').child(origin!).once(),
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff3D1975)));
          }

          ExamModel model = ExamModel.fromMap(snapshot.data!.snapshot.value as Map);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Text(
                  model.name,
                  style: const TextStyle(
                    color: Color(0xff3D1975),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('At just'),
                const SizedBox(height: 16),
                const Text(
                  '₹ 100',
                  style: TextStyle(
                    color: Color(0xff3D1975),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 64),
                Container(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("What you will get:", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          Text("Full Access to app"),
                          SizedBox(height: 16),
                          Text('All future updates of the app'),
                          SizedBox(height: 16),
                          Text('No time limit on membership'),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Button(
                  onPressed: () {
                    var options = {
                      'key': 'rzp_test_waMZtMqYkvyLTm',
                      'amount': 10000,
                      'name': 'Exam Bullet',
                      'description': 'Membership',
                      'prefill': {
                        'contact': FirebaseAuth.instance.currentUser!.phoneNumber,
                      }
                    };
                    _razorpay.submit(options);  // ✅ Correct method: submit()
                  },
                  text: 'Get Membership',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void paymentSuccess() {
    MembershipModel model = MembershipModel(
      widget.model,
      FirebaseAuth.instance.currentUser!.uid,
      DateTime.now().toIso8601String(),
    );
    FirebaseDatabase.instance
        .ref('memberships')
        .child(widget.model)
        .child(FirebaseAuth.instance.currentUser!.uid)
        .set(model.toMap())
        .then((value) {
      Navigator.pop(context);
    });
  }

  void paymentFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Failed')),
    );
  }
}
