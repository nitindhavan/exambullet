/// Small local date-formatting helpers. The app has no `intl` dependency by
/// convention, so these are hand-rolled rather than pulling in the package.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "18 Jul 2026"
String formatDate(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Relative day count vs now: "Today", "Tomorrow", "in 5 days", "12 days ago".
String relativeDay(int millis) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime.fromMillisecondsSinceEpoch(millis);
  final day = DateTime(target.year, target.month, target.day);
  final diff = day.difference(today).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1) return 'in $diff days';
  return '${-diff} days ago';
}
