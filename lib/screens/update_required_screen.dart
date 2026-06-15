import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent/utils/theme.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({Key? key, required this.updateUrl}) : super(key: key);
  final String updateUrl;

  Future<void> _launchUpdate() async {
    if (updateUrl.isEmpty) return;
    final Uri uri = Uri.parse(updateUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon illustration container
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3 * scale),
                                blurRadius: 20 * scale,
                                spreadRadius: 5 * scale,
                              ),
                            ],
                            border: Border.all(color: AppTheme.borderLight, width: 2),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: AppTheme.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.system_update_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Heading
              const Text(
                'Update Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Subheading
              const Text(
                'A newer, faster, and more stable version of the app is available. Please update now to continue your exam preparation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Update Button
              GestureDetector(
                onTap: _launchUpdate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Update Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Percent App Version 1.0.0',
                style: TextStyle(
                  color: AppTheme.textLight.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
