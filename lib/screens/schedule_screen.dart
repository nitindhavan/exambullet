import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/utils/date_utils.dart' as du;
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/ui/ui.dart';

/// One schedule event, flattened from an [ExamModel] so entries of the same
/// type (e.g. all exam dates) can be sorted together.
class _ScheduleEntry {
  final ExamModel exam;
  final String label;
  final int millis;
  const _ScheduleEntry(this.exam, this.label, this.millis);
}

// Section order matches the lifecycle of an exam: notification -> form
// window -> exam -> result. Must match the `label`s produced by
// ExamModel.scheduleEvents.
const _kSectionOrder = [
  'Notification',
  'Forms Open',
  'Forms Close',
  'Exam Date',
  'Result',
];

// "Out now" sections: a date already in the past is still relevant here — a
// notification that dropped or a form window that opened recently means you
// can act on it now. We keep those visible for a window after the date, then
// let them expire. All other sections show upcoming-only.
const _kOutNowLabels = {'Notification', 'Forms Open'};

// How long a past Notification/Forms-Open date stays visible as "out now".
const _kOutNowWindowDays = 45;

/// "Schedule" tab: every exam's announced dates, grouped into sections by
/// date TYPE (Notification, Forms Open, Forms Close, Exam Date, Result)
/// rather than by exam. Within each section, entries are sorted with the
/// closest date to today at the top.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen(
      {Key? key,
      this.allExams = const [],
      this.embedded = false,
      this.onExamTap})
      : super(key: key);
  final List<ExamModel> allExams;

  /// When true the screen renders only its body (no Scaffold/AppBar) so it can
  /// live inside the home tab shell.
  final bool embedded;

  /// Tapping a schedule card opens this exam (typically its dashboard). If
  /// null, cards are not tappable.
  final void Function(ExamModel exam)? onExamTap;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // null = "All" (show every section); otherwise the single date-type label
  // to show.
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Schedule'),
      body: body,
    );
  }

  Widget _buildBody() {
    final entries = <_ScheduleEntry>[];
    for (final exam in widget.allExams) {
      for (final e in exam.scheduleEvents) {
        entries.add(_ScheduleEntry(exam, e.key, e.value));
      }
    }

    if (entries.isEmpty) return const _EmptyState();

    // Compare against the start of today so a date later today still counts as
    // upcoming, not past.
    final nowDate = DateTime.now();
    final todayStart = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final now = todayStart.millisecondsSinceEpoch;
    final outNowCutoff =
        todayStart.subtract(const Duration(days: _kOutNowWindowDays))
            .millisecondsSinceEpoch;

    // Group by date type. For "out now" sections (Notification / Forms Open) we
    // also keep recently-passed dates so live opportunities stay visible;
    // everything else is upcoming-only.
    final byLabel = <String, List<_ScheduleEntry>>{};
    for (final e in entries) {
      final isOutNow = _kOutNowLabels.contains(e.label);
      final keep = isOutNow ? e.millis >= outNowCutoff : e.millis >= now;
      if (!keep) continue;
      byLabel.putIfAbsent(e.label, () => []).add(e);
    }
    // Out-now sections: most-recent first (freshly-out at top, then upcoming).
    // Upcoming-only sections: soonest first.
    for (final entry in byLabel.entries) {
      if (_kOutNowLabels.contains(entry.key)) {
        entry.value.sort((a, b) => b.millis.compareTo(a.millis));
      } else {
        entry.value.sort((a, b) => a.millis.compareTo(b.millis));
      }
    }

    // Sections that actually have data, in lifecycle order.
    final availableLabels =
        _kSectionOrder.where(byLabel.containsKey).toList();

    // Everything was filtered out (e.g. only stale past dates) → empty state.
    if (availableLabels.isEmpty) return const _EmptyState();

    // If the current filter no longer has data (shouldn't happen normally),
    // fall back to "All".
    final activeFilter =
        (_filter != null && byLabel.containsKey(_filter)) ? _filter : null;
    final shownLabels =
        activeFilter == null ? availableLabels : [activeFilter];

    return Column(
      children: [
        _FilterBar(
          labels: availableLabels,
          selected: activeFilter,
          onSelect: (label) => setState(() => _filter = label),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppTheme.space5, AppTheme.space4,
                AppTheme.space5, widget.embedded ? 88 : AppTheme.space8),
            children: [
              for (final label in shownLabels) ...[
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                ...byLabel[label]!.map((e) => _ScheduleCard(
                      entry: e,
                      onTap: widget.onExamTap == null
                          ? null
                          : () => widget.onExamTap!(e.exam),
                    )),
                const SizedBox(height: AppTheme.space6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal scrolling filter chips: "All" plus one per available date type.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final String? selected; // null = "All"
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            AppTheme.space5, AppTheme.space3, AppTheme.space5, 0),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final label in labels) ...[
            const SizedBox(width: AppTheme.space3),
            _Chip(
              label: label,
              selected: selected == label,
              onTap: () => onSelect(label),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.borderLight,
          ),
          boxShadow: selected ? null : AppTheme.softShadow,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entry, this.onTap});
  final _ScheduleEntry entry;
  final VoidCallback? onTap;

  Color get _accent {
    switch (entry.label) {
      case 'Exam Date':
        return AppTheme.error;
      case 'Forms Close':
        return AppTheme.warning;
      case 'Result':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  /// Trailing badge: for out-now sections a passed date reads "Out now" /
  /// "Open now"; otherwise the countdown ("in 5 days" etc).
  String get _trailingText {
    final isPast = entry.millis <
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .millisecondsSinceEpoch;
    if (isPast && _kOutNowLabels.contains(entry.label)) {
      return entry.label == 'Notification' ? 'Out now' : 'Open now';
    }
    return du.relativeDay(entry.millis);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space4),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: ExamIcon(
              iconKey: entry.exam.iconKey,
              imageUrl: entry.exam.icon,
              size: 28,
              color: _accent,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.exam.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  du.formatDate(entry.millis),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Text(
            _trailingText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppTheme.textLight),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_rounded,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: AppTheme.space4),
            Text(
              'No schedule dates yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              'Exam notification, form and exam dates will show up here\nonce announced.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
