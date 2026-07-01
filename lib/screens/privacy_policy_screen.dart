import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
                'Information We Collect',
                'We collect information to provide better services to our users. This includes your name, phone number, and app usage data.'),
            const SizedBox(height: 24),
            _buildSection(
                'How We Use Information',
                'The information we collect is used to maintain our services, protect our users, and communicate with you.'),
            const SizedBox(height: 24),
            _buildSection(
                'Information Sharing',
                'We do not share your personal information with companies, organizations, or individuals outside of Percent except in the following cases: with your consent, for legal reasons, etc.'),
            const SizedBox(height: 24),
            _buildSection(
                'Data Security',
                'We work hard to protect Percent and our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold.'),
            const SizedBox(height: 40),
            Text(
              'Last updated: June 2026',
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
        Text(
          title,
          style: AppTheme.headingMd,
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          content,
          style: AppTheme.body.copyWith(height: 1.6),
        ),
      ],
    );
  }
}
