import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Terms & Conditions'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please read these Terms & Conditions carefully before using Percent. By accessing or using the app, you agree to be bound by these terms.',
              style: AppTheme.body.copyWith(height: 1.6),
            ),
            const SizedBox(height: 28),
            _buildSection(
              '1. Acceptance of Terms',
              'By creating an account or using Percent, you confirm that you accept these Terms & Conditions and that you agree to comply with them. If you do not agree, you must not use the app.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. Use of the App',
              'Percent provides mock tests, practice questions, notes and related exam-preparation content. You agree to use the app only for lawful, personal, non-commercial purposes and not to misuse, copy, redistribute or resell any content.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. Accounts',
              'You are responsible for maintaining the confidentiality of your account and for all activity that occurs under it. You must provide accurate information and keep it up to date. We may suspend or terminate accounts that violate these terms.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Membership & Payments',
              'Certain content requires a paid membership for a specific exam. Prices are shown in the app before purchase and are charged as a one-time payment through our payment partner. Each membership grants access to the relevant exam for the duration specified on the membership screen (for example, a fixed number of days, or lifetime where indicated).',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Membership Duration & Expiry',
              'When you purchase a membership, its validity period is fixed at the time of purchase based on the duration shown for that exam. If a duration is set, access to premium content for that exam will end when the membership expires. Lifetime memberships do not expire. Changes made to an exam’s duration after your purchase do not affect memberships you have already bought.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '6. Refunds',
              'Memberships are generally non-refundable once activated, as access to digital content is granted immediately. If you believe you were charged in error or experienced a technical issue that prevented access, please contact support and we will review your request.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '7. Intellectual Property',
              'All content in Percent — including questions, tests, notes, text, graphics and logos — is owned by us or our licensors and is protected by law. You may not reproduce, distribute or create derivative works without our written permission.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '8. Disclaimer',
              'Percent is an exam-preparation aid provided on an “as is” basis. We do not guarantee any particular exam result or outcome. Content is provided for practice and study purposes and may not reflect the exact pattern of any official examination.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '9. Limitation of Liability',
              'To the maximum extent permitted by law, we are not liable for any indirect, incidental or consequential losses arising from your use of, or inability to use, the app.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '10. Changes to These Terms',
              'We may update these Terms & Conditions from time to time. Continued use of the app after changes are posted constitutes your acceptance of the revised terms.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '11. Contact',
              'If you have any questions about these Terms & Conditions, please reach out to us through the support options in the app.',
            ),
            const SizedBox(height: 40),
            Text(
              'Last updated: July 2026',
              style: AppTheme.bodySm.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headingMd),
        const SizedBox(height: AppTheme.space4),
        Text(content, style: AppTheme.body.copyWith(height: 1.6)),
      ],
    );
  }
}
