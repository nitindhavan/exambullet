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
  final nameController = TextEditingController();
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ── Top icon/logo ──────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xff3D1975),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Colors.white, size: 44),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Heading ────────────────────────────────────
                const Text(
                  "What's your\nname?",
                  style: TextStyle(
                    color: Color(0xff3D1975),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This is how you'll appear in the app.",
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Name input ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff3D1975).withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff3D1975),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xff3D1975),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Continue button ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: visible
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter your name')),
                              );
                              return;
                            }
                            setState(() => visible = true);
                            final authUser = FirebaseAuth.instance.currentUser!;
                            UserModel model = UserModel(
                              nameController.text.trim(),
                              authUser.phoneNumber ?? authUser.email ?? '',
                              authUser.uid,
                              [],
                            );
                            FirebaseDatabase.instance
                                .ref('users')
                                .child(model.uid)
                                .set(model.toMap())
                                .then((value) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(user: model)));
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3D1975),
                      disabledBackgroundColor:
                          const Color(0xff3D1975).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: visible
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Footer note ────────────────────────────────
                Center(
                  child: Text(
                    'Your name can be changed later from your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
