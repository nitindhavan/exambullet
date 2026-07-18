import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/ui/ui.dart';

class _MembershipEntry {
  _MembershipEntry({
    required this.since,
    required this.expiry,
  });
  final DateTime? since;
  final DateTime? expiry; // null = lifetime

  bool get isExpired =>
      expiry != null && DateTime.now().isAfter(expiry!);
}

/// Shows the user's single app-wide membership (unlocks all exams).
class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({Key? key}) : super(key: key);

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  bool _loading = true;
  List<_MembershipEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final entries = <_MembershipEntry>[];
    try {
      final snap =
          await FirebaseDatabase.instance.ref('appMemberships/$uid').once();
      if (snap.snapshot.exists) {
        final raw = snap.snapshot.value;
        bool active = true;
        DateTime? since;
        DateTime? expiry;
        if (raw is Map) {
          if (raw['isActive'] == false) active = false;
          final sinceRaw = raw['membershipDate'];
          if (sinceRaw is String) since = DateTime.tryParse(sinceRaw);
          final expRaw = raw['expiryDate'];
          if (expRaw is String) expiry = DateTime.tryParse(expRaw);
        }
        if (active) {
          entries.add(_MembershipEntry(since: since, expiry: expiry));
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  String _fmt(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'My Memberships'),
      body: _loading
          ? const PercentLoaderCentered()
          : _entries.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space6),
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => _card(_entries[i]),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_outlined,
                  color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('No memberships yet', style: AppTheme.headingMd),
            const SizedBox(height: 8),
            Text(
              'Get the All-Access Pass to unlock premium mock tests and features across every exam.',
              textAlign: TextAlign.center,
              style: AppTheme.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_MembershipEntry e) {
    final expired = e.isExpired;
    final Color accent = expired ? AppTheme.error : AppTheme.success;
    final Color accentLight =
        expired ? AppTheme.errorLight : AppTheme.successLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.brLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: AppTheme.brSm,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All-Access Pass',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingSm.copyWith(fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        expired ? 'Expired' : 'Active',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: AppTheme.primary, size: 15),
                    const SizedBox(width: 6),
                    Text('Premium Plan',
                        style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                if (e.since != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textSecondary, size: 13),
                      const SizedBox(width: 5),
                      Text('Since ${_fmt(e.since!)}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.expiry == null
                          ? Icons.all_inclusive_rounded
                          : (expired
                              ? Icons.event_busy_outlined
                              : Icons.event_available_outlined),
                      color: expired ? AppTheme.error : AppTheme.textSecondary,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      e.expiry == null
                          ? 'Lifetime'
                          : '${expired ? 'Expired' : 'Valid till'} ${_fmt(e.expiry!)}',
                      style: TextStyle(
                        color: expired ? AppTheme.error : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            expired ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
