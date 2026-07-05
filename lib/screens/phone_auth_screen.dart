import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent/screens/splash.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Phone-number sign-in (OTP). Works in two modes:
///  - Standalone sign-in for new/hesitant users who don't want Google.
///  - Linking: if a user is already signed in (e.g. via Google), the phone
///    credential is linked to that same account so their uid, data and
///    memberships are preserved.
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key, this.linkToCurrentUser = false})
      : super(key: key);

  /// When true, links the phone credential to the currently signed-in user
  /// instead of creating/entering a phone-only account.
  final bool linkToCurrentUser;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

enum _Step { enterNumber, enterOtp }

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.enterNumber;
  bool _loading = false;
  String? _verificationId;
  int? _resendToken;

  // Resend cooldown.
  Timer? _resendTimer;
  int _resendIn = 0;

  /// Default country code. India (+91) matches the app's audience; the user can
  /// still type a full +<code> number and we'll respect it.
  static const String _defaultDialCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final raw = _phoneController.text.trim().replaceAll(' ', '');
    if (raw.startsWith('+')) return raw;
    // Strip a leading 0 (common in local formats) before prepending the code.
    final local = raw.startsWith('0') ? raw.substring(1) : raw;
    return '$_defaultDialCode$local';
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendCode({bool isResend = false}) async {
    final number = _fullPhoneNumber;
    // Minimal sanity check: dial code + at least 7 digits.
    if (number.replaceAll(RegExp(r'\D'), '').length < 8) {
      _snack('Enter a valid phone number');
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number,
        forceResendingToken: isResend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android auto-retrieval / instant validation.
          await _completeSignIn(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _loading = false);
          _snack(_friendlyError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _step = _Step.enterOtp;
            _loading = false;
          });
          _startResendCooldown();
          if (isResend) _snack('Code resent', error: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to send code: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    final vId = _verificationId;
    if (code.length < 6 || vId == null) {
      _snack('Enter the 6-digit code');
      return;
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: vId,
      smsCode: code,
    );
    await _completeSignIn(credential);
  }

  Future<void> _completeSignIn(PhoneAuthCredential credential) async {
    setState(() => _loading = true);
    try {
      if (widget.linkToCurrentUser &&
          FirebaseAuth.instance.currentUser != null) {
        // Attach phone to the existing account — keeps uid/data/memberships.
        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
        if (!mounted) return;
        _snack('Phone number linked', error: false);
        Navigator.pop(context, true);
        return;
      }

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      // Splash creates/loads the users/{uid} record and routes to Home.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Splash()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(_friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Verification failed: $e');
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number looks invalid.';
      case 'invalid-verification-code':
        return 'Wrong code. Please check and try again.';
      case 'session-expired':
        return 'Code expired. Request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'A phone number is already linked to this account.';
      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            if (_step == _Step.enterOtp) {
              setState(() => _step = _Step.enterNumber);
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                _step == _Step.enterNumber
                    ? (widget.linkToCurrentUser
                        ? 'Add your phone'
                        : 'Sign in with phone')
                    : 'Verify your number',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == _Step.enterNumber
                    ? 'We’ll text you a 6-digit verification code.'
                    : 'Enter the code sent to $_fullPhoneNumber',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (_step == _Step.enterNumber)
                _buildNumberStep()
              else
                _buildOtpStep(),
              const SizedBox(height: 20),
              if (_step == _Step.enterNumber && !widget.linkToCurrentUser)
                const Center(child: LegalConsentText()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _defaultDialCode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: AppTheme.border),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                  onSubmitted: (_) => _loading ? null : _sendCode(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Send code',
          loading: _loading,
          onPressed: _loading ? null : () => _sendCode(),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondary, letterSpacing: 8, fontSize: 24),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 18),
            ),
            onChanged: (v) {
              if (v.length == 6 && !_loading) _verifyOtp();
            },
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Verify',
          loading: _loading,
          onPressed: _loading ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: _resendIn > 0
              ? Text(
                  'Resend code in ${_resendIn}s',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                )
              : TextButton(
                  onPressed: _loading ? null : () => _sendCode(isResend: true),
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
        ),
      ],
    );
  }
}
