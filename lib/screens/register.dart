import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

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
      backgroundColor: AppTheme.background,
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
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Colors.white, size: 44),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Heading ────────────────────────────────────
                Text(
                  "What's your\nname?",
                  style: AppTheme.displayLg.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                Text(
                  "This is how you'll appear in the app.",
                  style: AppTheme.body.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 40),

                // ── Name input ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.brMd,
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.brMd,
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space6, vertical: 18),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.space8),

                // ── Continue button ────────────────────────────
                AppButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.primary,
                  loading: visible,
                  onPressed: visible
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter your name')),
                            );
                            return;
                          }
                          if (name.length < 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Name must be at least 3 characters long')),
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
                            DateTime.now().toIso8601String(),
                          );
                          FirebaseDatabase.instance
                              .ref('users')
                              .child(model.uid)
                              .set(model.toMap())
                              .then((value) {
                            if (mounted) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(user: model)));
                            }
                          });
                        },
                ),

                const SizedBox(height: AppTheme.space7),

                // ── Footer note ────────────────────────────────
                Center(
                  child: Text(
                    'Your name can be changed later from your profile.',
                    textAlign: TextAlign.center,
                    style: AppTheme.caption.copyWith(fontSize: 13),
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
