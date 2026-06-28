import 'package:percent/models/exam.dart';
import 'package:percent/models/membership_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
// SDK only available on mobile
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart'
    if (dart.library.html) 'package:percent/utils/cf_web_stub.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart'
    if (dart.library.html) 'package:percent/utils/cf_web_stub.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart'
    if (dart.library.html) 'package:percent/utils/cf_web_stub.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart'
    if (dart.library.html) 'package:percent/utils/cf_web_stub.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart'
    if (dart.library.html) 'package:percent/utils/cf_web_stub.dart';
// Web JS interop — only available on web platform
import 'package:percent/utils/cashfree_web_interop.dart'
    if (dart.library.io) 'package:percent/utils/cashfree_web_interop_stub.dart';

class MemberShipScreen extends StatefulWidget {
  const MemberShipScreen({Key? key, required this.model}) : super(key: key);
  final String model;

  @override
  State<MemberShipScreen> createState() => _MemberShipScreenState();
}

class _MemberShipScreenState extends State<MemberShipScreen> {
  bool _isLoading = false;
  ExamModel? _exam;
  String? _cloudFunctionUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('appSettings').once();
      if (!mounted) return;
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        final settings = snap.snapshot.value as Map;
        setState(() => _cloudFunctionUrl = settings['cashfreeCloudFunctionUrl'] as String?);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _startPayment() async {
    if (_cloudFunctionUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment not configured. Try again later.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      final amount = ((_exam?.price ?? 10000) / 100).toStringAsFixed(2);
      final stage = kDebugMode ? 'TEST' : 'PROD';

      final orderResponse = await http.post(
        Uri.parse('$_cloudFunctionUrl/createCashfreeOrder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'orderAmount': amount,
          'customerEmail': user.email ?? '',
          'customerPhone': user.phoneNumber ?? '9999999999',
          'customerName': user.displayName ?? 'User',
          'stage': stage,
        }),
      );

      if (orderResponse.statusCode != 200) {
        throw Exception('Failed to create order: ${orderResponse.body}');
      }

      final orderData = jsonDecode(orderResponse.body);
      final paymentSessionId = orderData['payment_session_id'] as String;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (kIsWeb) {
        // Web: Cashfree JS SDK opens a payment modal (defined in web/index.html).
        // We register a one-shot callback on window and call the global JS function.
        final completer = Completer<String>();
        registerCashfreeCallback(completer);
        callCashfreeJs(paymentSessionId, kDebugMode ? 'sandbox' : 'production');

        final result = await completer.future;
        if (!mounted) return;
        if (result == 'success') {
          await _verifyAndActivate(orderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $result')),
          );
        }
      } else {
        // Mobile: use native SDK
        final session = CFSessionBuilder()
            .setEnvironment(kDebugMode ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION)
            .setOrderId(orderId)
            .setPaymentSessionId(paymentSessionId)
            .build();

        final cfPayment = CFWebCheckoutPaymentBuilder().setSession(session).build();

        CFPaymentGatewayService().setCallback(_onPaymentSuccess, _onPaymentError);
        CFPaymentGatewayService().doPayment(cfPayment);
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  // Mobile SDK callbacks
  void _onPaymentSuccess(String orderId) {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _verifyAndActivate(orderId);
  }

  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    final msg = errorResponse.getMessage() ?? 'Payment failed';
    if (!msg.toLowerCase().contains('cancel')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $msg')),
      );
    }
  }

  Future<void> _verifyAndActivate(String orderId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final verifyResponse = await http.post(
        Uri.parse('$_cloudFunctionUrl/verifyCashfreeOrder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId, 'stage': kDebugMode ? 'TEST' : 'PROD'}),
      );

      if (verifyResponse.statusCode != 200) throw Exception('Verification failed');

      final verifyData = jsonDecode(verifyResponse.body);
      if (verifyData['txStatus'] != 'SUCCESS') throw Exception('Payment not verified');

      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseDatabase.instance
          .ref('memberships')
          .child(widget.model)
          .child(uid)
          .set(MembershipModel(
            widget.model,
            uid,
            DateTime.now().toIso8601String(),
            paymentId: orderId,
          ).toMap());

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Verification error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment received (ID: $orderId) but activation failed. Contact support.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder(
        future: FirebaseDatabase.instance.ref('exams').child(widget.model).once(),
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Failed to load data.'));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final rawValue = snapshot.data!.snapshot.value;
          if (rawValue == null) return const Center(child: Text('Exam not found.'));

          final exam = ExamModel.fromMap(rawValue as Map, widget.model);
          if (_exam == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _exam = exam);
            });
          }

          return Column(
            children: [
              _Header(examName: exam.name, onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    children: [
                      _PriceCard(price: exam.price),
                      const SizedBox(height: 20),
                      _BenefitsCard(),
                      const SizedBox(height: 32),
                      _GetMembershipButton(isLoading: _isLoading, onPressed: _startPayment),
                      const SizedBox(height: 12),
                      const Text(
                        'One-time payment · Lifetime access',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unlock Premium',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(examName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
  const _PriceCard({required this.price});
  final int price;

  @override
  Widget build(BuildContext context) {
    final rupees = price ~/ 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lifetime Membership',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Pay once, access forever',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹$rupees',
                  style: const TextStyle(
                      color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
              const Text('one-time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
    {'icon': Icons.all_inclusive_rounded, 'label': 'No Expiry · Lifetime Access'},
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
          const Text('What you get',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ..._items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: Icon(item['icon'] as IconData, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(item['label'] as String,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── CTA Button ────────────────────────────────────────────────────────────────

class _GetMembershipButton extends StatelessWidget {
  const _GetMembershipButton({required this.isLoading, required this.onPressed});
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
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Get Membership',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      ),
    );
  }
}
