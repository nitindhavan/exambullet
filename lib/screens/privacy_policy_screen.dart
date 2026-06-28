import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
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
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
