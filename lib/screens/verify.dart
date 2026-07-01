import 'package:percent/screens/splash.dart';
import 'package:percent/widgets/heading.dart';
import 'package:percent/widgets/inputfield.dart';
import 'package:percent/widgets/ui/ui.dart';
import 'package:percent/utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyOTP extends StatefulWidget {
  const VerifyOTP({Key? key, required this.result}) : super(key: key);

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
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Verify'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(heading: 'Enter OTP sent to your phone'),
          InputField(
            controller: otpController,
            hint: 'Enter OTP',
          ),
          Padding(
            padding: AppTheme.screenPadding,
            child: AppButton(
              label: 'Continue',
              variant: AppButtonVariant.primary,
              loading: visible,
              onPressed: visible
                  ? null
                  : () async {
                      setState(() {
                        visible = true;
                      });
                      await widget.result
                          .confirm(otpController.text)
                          .then((value) {
                        if (mounted) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Splash()));
                        }
                      });
                    },
            ),
          ),
          const SizedBox(height: AppTheme.space8),
        ],
      ),
    );
  }
}

