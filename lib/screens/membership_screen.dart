import 'package:percent/models/exam.dart';
import 'package:percent/models/membership_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:razorpay_flutter_customui/razorpay_flutter_customui.dart';

// Amount in paise (₹100 = 10000 paise)
const int _amountPaise = 10000;

class MemberShipScreen extends StatefulWidget {
  const MemberShipScreen({Key? key, required this.model}) : super(key: key);

  final String model;

  @override
  State<MemberShipScreen> createState() => _MemberShipScreenState();
}

class _MemberShipScreenState extends State<MemberShipScreen> {
  bool _isLoading = false;
  String? _razorpayKey;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _loadRazorpayKey();
  }

  Future<void> _loadRazorpayKey() async {
    try {
      final snap =
          await FirebaseDatabase.instance.ref('appSettings').once();
      if (!mounted) return;
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        final settings = snap.snapshot.value as Map;
        final key = kDebugMode
            ? settings['razorpayKeyTest'] as String?
            : settings['razorpayKeyLive'] as String?;
        if (key != null && key.isNotEmpty) {
          _razorpay.initilizeSDK(key);
          setState(() => _razorpayKey = key);
        }
      }
    } catch (e) {
      debugPrint('Failed to load Razorpay key: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _startPayment() {
    if (_razorpayKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment not configured. Try again later.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final options = {
      'key': _razorpayKey!,
      'amount': _amountPaise,
      'currency': 'INR',
      'name': 'ExamBullet',
      'description': 'Lifetime Membership',
      'email': user.email ?? '',
      'contact': user.phoneNumber ?? '',
      'method': 'upi',
      '_[flow]': 'intent',
    };
    setState(() => _isLoading = true);
    _razorpay.submit(options);
  }

  Future<void> _onPaymentSuccess(Map<dynamic, dynamic> response) async {
    final paymentId = response['razorpay_payment_id'] as String? ?? '';
    debugPrint('Payment success: $paymentId');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final membership = MembershipModel(
      widget.model,
      uid,
      DateTime.now().toIso8601String(),
      paymentId: paymentId,
    );

    try {
      await FirebaseDatabase.instance
          .ref('memberships')
          .child(widget.model)
          .child(uid)
          .set(membership.toMap());

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving membership after payment: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful (ID: $paymentId) but activation failed. Contact support.',
          ),
        ),
      );
    }
  }

  void _onPaymentError(Map<dynamic, dynamic> response) {
    if (!mounted) return;
    setState(() => _isLoading = false);

    final code = response['data']?['code'] as int? ?? -1;
    if (code == Razorpay.PAYMENT_CANCELLED) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed: ${response['data']?['message'] ?? 'Unknown error'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder(
        future:
            FirebaseDatabase.instance.ref('exams').child(widget.model).once(),
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load data.'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final rawValue = snapshot.data!.snapshot.value;
          if (rawValue == null) {
            return const Center(child: Text('Exam not found.'));
          }

          final exam = ExamModel.fromMap(rawValue as Map, widget.model);

          return Column(
            children: [
              _Header(
                  examName: exam.name, onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    children: [
                      _PriceCard(),
                      const SizedBox(height: 20),
                      _BenefitsCard(),
                      const SizedBox(height: 32),
                      _GetMembershipButton(
                        isLoading: _isLoading,
                        onPressed: _startPayment,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'One-time payment · Lifetime access',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.examName, required this.onBack});
  final String examName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unlock Premium',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      examName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Price Card ────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lifetime Membership',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pay once, access forever',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹100',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                'one-time',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Benefits Card ─────────────────────────────────────────────────────────────

class _BenefitsCard extends StatelessWidget {
  static const List<Map<String, dynamic>> _items = [
    {'icon': Icons.lock_open_rounded, 'label': 'Full Access to All Content'},
    {'icon': Icons.update_rounded, 'label': 'All Future Updates Included'},
    {
      'icon': Icons.all_inclusive_rounded,
      'label': 'No Expiry · Lifetime Access'
    },
    {'icon': Icons.support_agent_rounded, 'label': 'Priority Support'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you get',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA Button ────────────────────────────────────────────────────────────────

class _GetMembershipButton extends StatelessWidget {
  const _GetMembershipButton(
      {required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Get Membership',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
