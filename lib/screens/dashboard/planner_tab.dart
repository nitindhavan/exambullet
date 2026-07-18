import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/models/planner_task_model.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/exam_icon.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/sign_in_sheet.dart';
import 'package:percent/widgets/ui/ui.dart';

/// Study planner — a simple, free, per-exam checklist.
///
/// Tasks live at `planner/{uid}/{examId}/{taskId}` so each exam a user is
/// preparing for gets its own plan. Slots into the home tab switcher (see
/// [Home]); an exam rail at the top selects which exam's plan is shown.
class PlannerTab extends StatefulWidget {
  const PlannerTab({Key? key, this.goalExams = const [], this.singleExam})
      : super(key: key);

  /// Multi-exam mode: the exams to offer via a top rail (legacy usage).
  final List<ExamModel> goalExams;

  /// Single-exam mode: when set, the planner operates on just this exam (no
  /// rail). Used when embedded inside a specific exam's dashboard.
  final ExamModel? singleExam;

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  String? _selectedExamId;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DatabaseReference _ref(String examId) => FirebaseDatabase.instance
      .ref('planner')
      .child(_uid)
      .child(examId);

  @override
  Widget build(BuildContext context) {
    // Guests have no uid to scope tasks to — nudge them to sign in.
    if (_uid.isEmpty) {
      return _GuestState(onSignIn: () => showSignInSheet(context));
    }

    // Single-exam mode (embedded in an exam dashboard): no rail, just the plan.
    final single = widget.singleExam;
    if (single != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: _ExamPlanner(
          key: ValueKey(single.id),
          exam: single,
          ref: _ref(single.id),
        ),
      );
    }

    if (widget.goalExams.isEmpty) {
      return const _NoExamsState();
    }

    // Keep the selection valid as goals change.
    final exams = widget.goalExams;
    if (!exams.any((e) => e.id == _selectedExamId)) {
      _selectedExamId = exams.first.id;
    }
    final selectedExam = exams.firstWhere((e) => e.id == _selectedExamId);

    return Column(
      children: [
        _ExamRail(
          exams: exams,
          selectedId: _selectedExamId!,
          onSelect: (id) => setState(() => _selectedExamId = id),
        ),
        // Connected "room" panel — rounded white surface with a top shadow, so
        // the rail reads as sitting above the plan (matches the My Rooms tab).
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: _ExamPlanner(
                key: ValueKey(selectedExam.id),
                exam: selectedExam,
                ref: _ref(selectedExam.id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Exam switcher rail
// ══════════════════════════════════════════════════════════════════════════════

class _ExamRail extends StatelessWidget {
  const _ExamRail({
    required this.exams,
    required this.selectedId,
    required this.onSelect,
  });
  final List<ExamModel> exams;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          final isSelected = exam.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => onSelect(exam.id),
              child: SizedBox(
                width: 72,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: AppTheme.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade200,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: ExamIcon(
                              iconKey: exam.iconKey,
                              imageUrl: exam.icon,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        exam.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Per-exam planner — checklist for one exam
// ══════════════════════════════════════════════════════════════════════════════

class _ExamPlanner extends StatelessWidget {
  const _ExamPlanner({Key? key, required this.exam, required this.ref})
      : super(key: key);
  final ExamModel exam;
  final DatabaseReference ref;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const PercentLoaderCentered();
        }

        final tasks = <PlannerTask>[];
        final value = snap.data!.snapshot.value;
        if (value != null) {
          final raw = value as Map;
          raw.forEach((key, v) {
            tasks.add(PlannerTask.fromMap(v as Map, key as String));
          });
          // Undone first, then by creation time — newest additions on top.
          tasks.sort((a, b) {
            if (a.done != b.done) return a.done ? 1 : -1;
            return b.createdAt.compareTo(a.createdAt);
          });
        }

        final done = tasks.where((t) => t.done).length;

        return Stack(
          children: [
            Column(
              children: [
                _Header(examName: exam.name, done: done, total: tasks.length),
                Expanded(
                  child: tasks.isEmpty
                      ? _EmptyState(onAdd: () => _addTask(context))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => _TaskTile(
                            task: tasks[i],
                            onToggle: () => _toggle(tasks[i]),
                            onDelete: () => _delete(tasks[i]),
                          ),
                        ),
                ),
              ],
            ),
            // Floating add button (hidden on the empty state — it has its own CTA)
            if (tasks.isNotEmpty)
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _addTask(context),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add task',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Firebase writes ─────────────────────────────────────────────────────────

  Future<void> _toggle(PlannerTask task) {
    HapticFeedback.selectionClick();
    return ref.child(task.id).update({'done': !task.done});
  }

  Future<void> _delete(PlannerTask task) {
    HapticFeedback.lightImpact();
    return ref.child(task.id).remove();
  }

  Future<void> _create(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    final taskRef = ref.push();
    final id = taskRef.key!;
    return taskRef.set(PlannerTask(
      id: id,
      text: trimmed,
      done: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  void _addTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(onSubmit: _create),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Header — title + progress
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.examName,
    required this.done,
    required this.total,
  });
  final String examName;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$examName Planner',
                    style: AppTheme.headingMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$done / $total done',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: pct),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: AppTheme.borderLight,
                  color: pct >= 1 ? AppTheme.success : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pct >= 1
                  ? 'All done — great work! 🎉'
                  : '${((1 - pct) * total).round()} task${((1 - pct) * total).round() == 1 ? '' : 's'} left',
              style: AppTheme.caption,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Task tile — checkbox + text, swipe to delete
// ══════════════════════════════════════════════════════════════════════════════

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
  final PlannerTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.error, size: 22),
      ),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.done ? AppTheme.success : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: task.done ? AppTheme.success : AppTheme.border,
                    width: 2,
                  ),
                ),
                child: task.done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: task.done
                        ? AppTheme.textLight
                        : AppTheme.textPrimary,
                    decoration:
                        task.done ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add-task bottom sheet
// ══════════════════════════════════════════════════════════════════════════════

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.onSubmit});
  final Future<void> Function(String) onSubmit;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    await widget.onSubmit(_controller.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('New study task', style: AppTheme.headingMd),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. Finish Percentage chapter',
                hintStyle: const TextStyle(color: AppTheme.textLight),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Add task',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// States: shimmer / empty / no-exams / guest
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

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
              child: Icon(Icons.checklist_rounded,
                  size: 40, color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text('Plan your prep',
                style: AppTheme.headingSm.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Add study tasks for this exam and tick them off as you go.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add your first task',
              onPressed: onAdd,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoExamsState extends StatelessWidget {
  const _NoExamsState();

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
              child: Icon(Icons.flag_rounded,
                  size: 38, color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text('No exams yet',
                style: AppTheme.headingSm.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Add the exams you are preparing for to start planning. Each exam gets its own study checklist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
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
              child: Icon(Icons.lock_open_rounded,
                  size: 38, color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text('Sign in to plan',
                style: AppTheme.headingSm.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Sign in to save your study checklist and sync it across devices.',
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
