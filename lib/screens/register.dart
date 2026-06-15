import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

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
                const Text(
                  "What's your\nname?",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This is how you'll appear in the app.",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Name input ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor:
                          AppTheme.primary.withValues(alpha: 0.6),
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
                const Center(
                  child: Text(
                    'Your name can be changed later from your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textLight,
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
