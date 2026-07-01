import 'package:percent/models/exam.dart';
import 'package:percent/models/membership_model.dart';
import 'package:percent/screens/terms_conditions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';
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
      // Stamp the expiry at purchase from the exam's duration (0 = lifetime).
      final now = DateTime.now();
      final durationDays = _exam?.membershipDurationDays ?? 365;
      final expiry = durationDays > 0
          ? now.add(Duration(days: durationDays)).toIso8601String()
          : null;
      await FirebaseDatabase.instance
          .ref('memberships')
          .child(widget.model)
          .child(uid)
          .set(MembershipModel(
            widget.model,
            uid,
            now.toIso8601String(),
            paymentId: orderId,
            expiryDate: expiry,
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
      appBar: AppTopBar(title: _exam?.name ?? 'Membership'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.space6, AppTheme.space7, AppTheme.space6, AppTheme.space8),
            child: Column(
              children: [
                _PriceCard(
                    price: exam.price,
                    durationDays: exam.membershipDurationDays),
                const SizedBox(height: AppTheme.space6),
                _BenefitsCard(durationDays: exam.membershipDurationDays),
                const SizedBox(height: AppTheme.space8),
                _GetMembershipButton(isLoading: _isLoading, onPressed: _startPayment),
                const SizedBox(height: AppTheme.space4),
                Text(
                  exam.membershipDurationDays == 0
                      ? 'One-time payment · Lifetime access'
                      : 'One-time payment · ${_durationLabel(exam.membershipDurationDays)} access',
                  style: AppTheme.bodySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space3),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen()),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: 'By purchasing, you agree to our ',
                      style: AppTheme.caption,
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Duration helper ───────────────────────────────────────────────────────────

/// Human-friendly label for a membership duration in days.
/// 0 → 'Lifetime'; multiples of 365 → 'N year(s)'; 30 → '1 month'; else 'N days'.
String _durationLabel(int days) {
  if (days <= 0) return 'Lifetime';
  if (days % 365 == 0) {
    final y = days ~/ 365;
    return y == 1 ? '1 year' : '$y years';
  }
  if (days % 30 == 0) {
    final m = days ~/ 30;
    return m == 1 ? '1 month' : '$m months';
  }
  return days == 1 ? '1 day' : '$days days';
}

// ── Price Card ────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price, required this.durationDays});
  final int price;
  final int durationDays;

  @override
  Widget build(BuildContext context) {
    final rupees = price ~/ 100;
    final isLifetime = durationDays <= 0;
    final label = _durationLabel(durationDays);
    return AppCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppTheme.space7, horizontal: AppTheme.space7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isLifetime ? 'Lifetime Membership' : '$label Membership',
                    style: AppTheme.headingSm),
                const SizedBox(height: 4),
                Text(
                    isLifetime
                        ? 'Unlock this exam forever'
                        : 'Unlock this exam for $label',
                    style: AppTheme.bodySm),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹$rupees',
                  style: const TextStyle(
                      color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
              Text(isLifetime ? 'one-time' : 'for $label', style: AppTheme.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Benefits Card ─────────────────────────────────────────────────────────────

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.durationDays});
  final int durationDays;

  List<Map<String, dynamic>> get _items => [
        const {'icon': Icons.lock_open_rounded, 'label': 'Full access to all content of this exam'},
        const {'icon': Icons.update_rounded, 'label': 'All future updates for this exam included'},
        durationDays <= 0
            ? const {'icon': Icons.all_inclusive_rounded, 'label': 'No expiry · Lifetime access'}
            : {'icon': Icons.schedule_rounded, 'label': 'Valid for ${_durationLabel(durationDays)}'},
        const {'icon': Icons.support_agent_rounded, 'label': 'Priority support'},
      ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you get', style: AppTheme.headingMd),
          const SizedBox(height: AppTheme.space5),
          ..._items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryLight, borderRadius: AppTheme.brSm),
                      child: Icon(item['icon'] as IconData, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(item['label'] as String,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary)),
                    ),
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
    return AppButton(
      label: 'Get Membership',
      icon: Icons.workspace_premium_rounded,
      loading: isLoading,
      onPressed: onPressed,
      height: 56,
    );
  }
}
