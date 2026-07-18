import 'package:percent/screens/terms_conditions_screen.dart';
import 'package:percent/services/membership_service.dart';
import 'package:percent/services/analytics_service.dart';
import 'package:percent/services/guest_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';
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
  String? _cloudFunctionUrl;

  // Three membership plans (durations fixed; prices from appSettings, in paise).
  late List<_Plan> _plans;
  int _selectedIndex = 1; // default to the 6-month plan
  bool _settingsLoaded = false;

  _Plan get _selectedPlan => _plans[_selectedIndex];

  @override
  void initState() {
    super.initState();
    // Default prices (paise) until appSettings loads: ₹49 / ₹99 / ₹149.
    _plans = [
      _Plan(months: 3, days: 90, price: 4900, label: '3 Months'),
      _Plan(months: 6, days: 180, price: 9900, label: '6 Months'),
      _Plan(months: 12, days: 365, price: 14900, label: '12 Months'),
    ];
    _loadSettings();
    Analytics.instance.logViewPaywall();
  }

  Future<void> _loadSettings() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('appSettings').once();
      if (!mounted) return;
      if (snap.snapshot.exists && snap.snapshot.value != null) {
        final settings = snap.snapshot.value as Map;
        int paise(dynamic v, int fallback) =>
            v is num ? v.toInt() : fallback;
        setState(() {
          _cloudFunctionUrl = settings['cashfreeCloudFunctionUrl'] as String?;
          _plans[0].price = paise(settings['membershipPrice3m'], 4900);
          _plans[1].price = paise(settings['membershipPrice6m'], 9900);
          _plans[2].price = paise(settings['membershipPrice12m'], 14900);
          _settingsLoaded = true;
        });
      } else {
        setState(() => _settingsLoaded = true);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      if (mounted) setState(() => _settingsLoaded = true);
    }
  }

  Future<void> _startPayment() async {
    // HARD gate: a purchase must be tied to a real account so the membership is
    // saved and recoverable. A guest (anonymous) must sign in first — their
    // guest data links over, so nothing is lost.
    if (GuestGate.isGuest) {
      final ok = await GuestGate.requireAccount(context, reason: 'membership');
      if (!mounted) return;
      if (!ok) return; // user cancelled sign-in
    }

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
      final amount = (_selectedPlan.price / 100).toStringAsFixed(2);
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
      // Stamp the expiry at purchase from the selected plan's duration.
      final now = DateTime.now();
      final expiry =
          now.add(Duration(days: _selectedPlan.days)).toIso8601String();
      // App-wide membership: one record unlocks every exam.
      await MembershipService.activate(uid, paymentId: orderId, expiryDate: expiry);

      Analytics.instance.logPurchase(
        amount: _selectedPlan.price / 100,
        currency: 'INR',
        plan: _selectedPlan.label,
      );

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
      appBar: const AppTopBar(title: 'Membership'),
      body: !_settingsLoaded
          ? const PercentLoaderCentered()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.space6, AppTheme.space7, AppTheme.space6, AppTheme.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose your plan', style: AppTheme.headingMd),
                  const SizedBox(height: AppTheme.space5),
                  for (int i = 0; i < _plans.length; i++) ...[
                    _PlanCard(
                      plan: _plans[i],
                      selected: i == _selectedIndex,
                      bestValue: i == _plans.length - 1,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                    if (i != _plans.length - 1)
                      const SizedBox(height: AppTheme.space4),
                  ],
                  const SizedBox(height: AppTheme.space6),
                  _BenefitsCard(durationDays: _selectedPlan.days),
                  const SizedBox(height: AppTheme.space8),
                  _GetMembershipButton(
                    isLoading: _isLoading,
                    price: _selectedPlan.price,
                    onPressed: _startPayment,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Center(
                    child: Text(
                      'One-time payment · ${_selectedPlan.label} access to all exams',
                      style: AppTheme.bodySm,
                      textAlign: TextAlign.center,
                    ),
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
            ),
    );
  }
}

// ── Plan ──────────────────────────────────────────────────────────────────────

class _Plan {
  _Plan({
    required this.months,
    required this.days,
    required this.price, // paise
    required this.label,
  });
  final int months;
  final int days;
  int price;
  final String label;
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

// ── Plan Card (selectable) ──────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.bestValue,
    required this.onTap,
  });
  final _Plan plan;
  final bool selected;
  final bool bestValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rupees = plan.price ~/ 100;
    final perMonth = (plan.price / plan.months / 100);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.space6, horizontal: AppTheme.space6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : Colors.white,
          borderRadius: AppTheme.brLg,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.borderLight,
                    width: 2),
                color: selected ? AppTheme.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: AppTheme.headingSm),
                      if (bestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('BEST VALUE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('₹${perMonth.toStringAsFixed(0)}/month · all exams',
                      style: AppTheme.bodySm),
                ],
              ),
            ),
            Text('₹$rupees',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1)),
          ],
        ),
      ),
    );
  }
}

// ── Benefits Card ─────────────────────────────────────────────────────────────

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.durationDays});
  final int durationDays;

  List<Map<String, dynamic>> get _items => [
        const {'icon': Icons.lock_open_rounded, 'label': 'Full access to all exams and content'},
        const {'icon': Icons.update_rounded, 'label': 'All future exams and updates included'},
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
  const _GetMembershipButton({
    required this.isLoading,
    required this.price,
    required this.onPressed,
  });
  final bool isLoading;
  final int price; // paise
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Get Membership · ₹${price ~/ 100}',
      icon: Icons.workspace_premium_rounded,
      loading: isLoading,
      onPressed: onPressed,
      height: 56,
    );
  }
}
