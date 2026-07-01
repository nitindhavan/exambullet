import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:percent/screens/privacy_policy_screen.dart';
import 'package:percent/screens/terms_conditions_screen.dart';
import 'package:percent/utils/theme.dart';

/// "By continuing, you agree to our Terms & Conditions and Privacy Policy"
/// with the Terms and Privacy portions tappable, opening their pages.
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({
    Key? key,
    this.prefix = 'By continuing, you agree to our ',
    this.fontSize = 12,
  }) : super(key: key);

  final String prefix;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.caption.copyWith(fontSize: fontSize);
    final link = base.copyWith(
      color: AppTheme.primary,
      fontWeight: FontWeight.w700,
    );

    return Text.rich(
      TextSpan(
        text: prefix,
        style: base,
        children: [
          TextSpan(
            text: 'Terms & Conditions',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen()),
                  ),
          ),
          TextSpan(text: ' and ', style: base),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
