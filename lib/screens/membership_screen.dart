import 'package:percent/models/exam.dart';
import 'package:percent/models/membership_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MemberShipScreen extends StatefulWidget {
  const MemberShipScreen({Key? key, required this.model}) : super(key: key);

  final String model;

  @override
  State<MemberShipScreen> createState() => _MemberShipScreenState();
}

class _MemberShipScreenState extends State<MemberShipScreen> {
  bool _isLoading = false;

  static const Color _primary = Color(0xff3D1975);
  static const Color _accent = Color(0xff6A2FD8);
  static const Color _bg = Color(0xffF6F2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder(
        future:
            FirebaseDatabase.instance.ref('exams').child(widget.model).once(),
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load data.'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          final rawValue = snapshot.data!.snapshot.value;
          if (rawValue == null) {
            return const Center(child: Text('Exam not found.'));
          }

          final exam = ExamModel.fromMap(rawValue as Map);

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────
              _Header(
                  examName: exam.name, onBack: () => Navigator.pop(context)),

              // ── Scrollable content ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    children: [
                      // Price card
                      _PriceCard(),
                      const SizedBox(height: 20),

                      // Benefits card
                      _BenefitsCard(),
                      const SizedBox(height: 32),

                      // CTA
                      _GetMembershipButton(
                        isLoading: _isLoading,
                        onPressed: _saveAndActivate,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'One-time payment · Lifetime access',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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

  Future<void> _saveAndActivate() async {
    setState(() => _isLoading = true);

    final membership = MembershipModel(
      widget.model,
      FirebaseAuth.instance.currentUser!.uid,
      DateTime.now().toIso8601String(),
    );

    try {
      await FirebaseDatabase.instance
          .ref('memberships')
          .child(widget.model)
          .child(FirebaseAuth.instance.currentUser!.uid)
          .set(membership.toMap());

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    }
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
          colors: [Color(0xff3D1975), Color(0xff6A2FD8)],
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
                  color: Colors.white.withOpacity(0.18),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Lifetime Membership',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff3D1975),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pay once, access forever',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '₹100',
                style: TextStyle(
                  color: Color(0xff3D1975),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                'one-time',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you get',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff3D1975),
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
                      color: const Color(0xffEDE8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: const Color(0xff3D1975), size: 18),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    item['label'] as String,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xff2D2D2D)),
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
            colors: [Color(0xff3D1975), Color(0xff6A2FD8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3D1975).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
