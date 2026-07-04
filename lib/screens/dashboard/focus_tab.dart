import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/focus_session_model.dart';
import 'package:percent/services/focus_service.dart';
import 'package:percent/services/focus_stats.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/sign_in_sheet.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Focus tab — a study-time tracker with a manual Start/Stop timer plus streak,
/// history, insights, and a GitHub-style contribution calendar.
///
/// The running timer is wall-clock based (see [FocusService]) so elapsed time
/// stays correct across minimise / kill / reopen; an ongoing notification shows
/// while a session is active.
class FocusTab extends StatelessWidget {
  const FocusTab({Key? key, required this.goalExams}) : super(key: key);

  final List<ExamModel> goalExams;

  bool get _signedIn => FirebaseAuth.instance.currentUser != null;

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return _GuestState(onSignIn: () => showSignInSheet(context));
    }

    return StreamBuilder<List<FocusSession>>(
      stream: FocusService.sessionsStream(),
      builder: (context, sessionSnap) {
        final sessions = sessionSnap.data ?? const <FocusSession>[];
        final stats = FocusStats.from(sessions);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _SectionTitle('Focus Timer', Icons.timer_rounded),
            _TimerCard(goalExams: goalExams),
            const SizedBox(height: AppTheme.space6),

            // Streak + quick totals
            _StreakRow(stats: stats),
            const SizedBox(height: AppTheme.space6),

            const _SectionTitle('Activity', Icons.grid_view_rounded),
            _ContributionCalendar(stats: stats),
            const SizedBox(height: AppTheme.space6),

            const _SectionTitle('Insights', Icons.insights_rounded),
            _Insights(stats: stats),
            const SizedBox(height: AppTheme.space6),

            const _SectionTitle('History', Icons.history_rounded),
            _History(sessions: sessions),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section title
// ══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(text, style: AppTheme.headingMd),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Timer card — exam picker + stopwatch + Start/Stop
// ══════════════════════════════════════════════════════════════════════════════

class _TimerCard extends StatefulWidget {
  const _TimerCard({required this.goalExams});
  final List<ExamModel> goalExams;

  @override
  State<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<_TimerCard> {
  ExamModel? _selected;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.goalExams.isNotEmpty) _selected = widget.goalExams.first;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicking(bool active) {
    if (active && _ticker == null) {
      // Rebuild once a second so the elapsed display updates.
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!active && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  String _fmt(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ActiveFocus?>(
      stream: FocusService.activeStream(),
      builder: (context, snap) {
        final active = snap.data;
        _ensureTicking(active != null);

        final elapsedSec = active == null
            ? 0
            : ((DateTime.now().millisecondsSinceEpoch - active.startedAt) ~/
                    1000)
                .clamp(0, FocusService.maxSessionSec);

        return Container(
          padding: const EdgeInsets.all(AppTheme.space6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppTheme.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTheme.brXl,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Which exam
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  active != null ? 'Studying' : 'Focus on',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              if (active != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(active.examName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                )
              else
                _ExamDropdown(
                  exams: widget.goalExams,
                  selected: _selected,
                  onChanged: (e) => setState(() => _selected = e),
                ),

              const SizedBox(height: AppTheme.space6),

              // Stopwatch
              Text(
                _fmt(elapsedSec),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppTheme.space6),

              // Start / Stop
              if (active != null)
                Row(
                  children: [
                    Expanded(
                      child: _WhiteButton(
                        label: 'Stop & Save',
                        icon: Icons.stop_rounded,
                        onTap: () async {
                          final saved = await FocusService.stop(active);
                          if (context.mounted && saved > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Saved ${_fmt(saved)} of focus 🎯')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GhostIcon(
                      icon: Icons.close_rounded,
                      onTap: () => _confirmDiscard(context),
                    ),
                  ],
                )
              else
                _WhiteButton(
                  label: 'Start Focus',
                  icon: Icons.play_arrow_rounded,
                  onTap: _selected == null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          FocusService.start(
                              _selected!.id, _selected!.name);
                        },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard session?'),
        content: const Text(
            'This will end the timer without saving the time studied.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (yes == true) await FocusService.discard();
  }
}

class _ExamDropdown extends StatelessWidget {
  const _ExamDropdown({
    required this.exams,
    required this.selected,
    required this.onChanged,
  });
  final List<ExamModel> exams;
  final ExamModel? selected;
  final ValueChanged<ExamModel> onChanged;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('Add a goal exam to start focusing',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppTheme.brMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExamModel>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.primary,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          items: exams
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (e) {
            if (e != null) onChanged(e);
          },
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.brMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostIcon extends StatelessWidget {
  const _GhostIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: AppTheme.brMd,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Streak + quick totals
// ══════════════════════════════════════════════════════════════════════════════

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.stats});
  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricCard(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xffF97316),
          value: '${stats.currentStreak}',
          label: stats.currentStreak == 1 ? 'day streak' : 'day streak',
        ),
        const SizedBox(width: AppTheme.space4),
        _MetricCard(
          icon: Icons.timelapse_rounded,
          color: AppTheme.primary,
          value: _hm(stats.totalSec),
          label: 'total focus',
        ),
        const SizedBox(width: AppTheme.space4),
        _MetricCard(
          icon: Icons.emoji_events_rounded,
          color: AppTheme.success,
          value: '${stats.longestStreak}',
          label: 'best streak',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.brLg,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GitHub-style contribution calendar (last ~17 weeks)
// ══════════════════════════════════════════════════════════════════════════════

class _ContributionCalendar extends StatelessWidget {
  const _ContributionCalendar({required this.stats});
  final FocusStats stats;

  static const int _weeks = 17; // ~4 months

  Color _cellColor(int sec) {
    if (sec <= 0) return AppTheme.borderLight;
    final mins = sec / 60;
    if (mins < 15) return AppTheme.primary.withValues(alpha: 0.25);
    if (mins < 45) return AppTheme.primary.withValues(alpha: 0.45);
    if (mins < 90) return AppTheme.primary.withValues(alpha: 0.7);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    // Start from the Sunday of the week (_weeks-1) weeks ago.
    final startOfThisWeek =
        todayDateOnly.subtract(Duration(days: todayDateOnly.weekday % 7));
    final start =
        startOfThisWeek.subtract(const Duration(days: (_weeks - 1) * 7));

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.brLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${stats.activeDays} active days',
                  style: AppTheme.headingSm),
              Text('last 4 months', style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 12),
          // Grid: columns = weeks, rows = 7 days (Sun..Sat)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // most recent week visible first
            child: Column(
              children: List.generate(7, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: List.generate(_weeks, (col) {
                      final date = start.add(Duration(days: col * 7 + row));
                      final isFuture = date.isAfter(todayDateOnly);
                      final sec = stats.secondsOn(date);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isFuture
                                ? Colors.transparent
                                : _cellColor(sec),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: AppTheme.caption),
              const SizedBox(width: 6),
              ...[0.0, 0.25, 0.45, 0.7, 1.0].map((a) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: a == 0
                            ? AppTheme.borderLight
                            : AppTheme.primary.withValues(alpha: a),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )),
              const SizedBox(width: 3),
              Text('More', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Insights — per-exam breakdown + averages
// ══════════════════════════════════════════════════════════════════════════════

class _Insights extends StatelessWidget {
  const _Insights({required this.stats});
  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.sessionCount == 0) {
      return const _InfoCard(
        icon: Icons.insights_rounded,
        title: 'No focus yet',
        subtitle: 'Start your first session and your study insights will build here.',
      );
    }

    final exams = stats.examsByTime;
    final maxSec = exams.isEmpty ? 1 : exams.first.value;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.brLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Avg / active day',
                    value: _hm(stats.avgPerActiveDaySec)),
              ),
              Container(width: 1, height: 34, color: AppTheme.borderLight),
              Expanded(
                child: _MiniStat(
                    label: 'Best day', value: _hm(stats.bestDaySec)),
              ),
              Container(width: 1, height: 34, color: AppTheme.borderLight),
              Expanded(
                child: _MiniStat(
                    label: 'Sessions', value: '${stats.sessionCount}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 16),
          Text('Time per exam', style: AppTheme.headingSm),
          const SizedBox(height: 12),
          ...exams.map((e) {
            final name = stats.examNames[e.key] ?? 'Exam';
            final frac = maxSec == 0 ? 0.0 : e.value / maxSec;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(_hm(e.value),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: AppTheme.borderLight,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// History — sessions grouped by day
// ══════════════════════════════════════════════════════════════════════════════

class _History extends StatelessWidget {
  const _History({required this.sessions});
  final List<FocusSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _InfoCard(
        icon: Icons.history_rounded,
        title: 'No sessions yet',
        subtitle: 'Your completed focus sessions will be listed here.',
      );
    }

    // Group by day (sessions already sorted newest-first).
    final groups = <String, List<FocusSession>>{};
    for (final s in sessions) {
      groups.putIfAbsent(s.day, () => []).add(s);
    }
    // Cap the history list so very active users don't render thousands.
    final days = groups.keys.take(30).toList();

    return Column(
      children: days.map((day) {
        final items = groups[day]!;
        final dayTotal = items.fold(0, (m, s) => m + s.durationSec);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppTheme.space5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.brLg,
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_prettyDay(day), style: AppTheme.headingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_hm(dayTotal),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 7, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s.examName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text('${_startTime(s.startedAt)} · ${_hm(s.durationSec)}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared small pieces
// ══════════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.brLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: AppTheme.primaryLight, shape: BoxShape.circle),
            child: Icon(icon,
                color: AppTheme.primary.withValues(alpha: 0.6), size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.headingSm),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _GuestState extends StatelessWidget {
  const _GuestState({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.timer_rounded,
                  size: 38, color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text('Sign in to track focus',
                style: AppTheme.headingSm.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Sign in to time your study sessions and build your streak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Sign In', onPressed: onSignIn, expand: false),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Formatting helpers
// ══════════════════════════════════════════════════════════════════════════════

String _hm(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  if (m > 0) return '${m}m';
  return '${totalSec}s';
}

String _startTime(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '$h:$mm $ap';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _prettyDay(String dayKey) {
  // dayKey is "YYYY-MM-DD"
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final date = DateTime(
      int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final now = DateTime.now();
  final todayOnly = DateTime(now.year, now.month, now.day);
  final diff = todayOnly.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
