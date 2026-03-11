import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/exam.dart';
import 'package:percent/screens/membership_screen.dart';

class NotesTab extends StatelessWidget {
  const NotesTab(
      {Key? key, required this.exam, required this.hasMembership})
      : super(key: key);
  final ExamModel exam;
  final bool hasMembership;

  static const _tagColors = {
    'Important': Color(0xffF44336),
    'Formula': Color(0xff2196F3),
    'Concept': Color(0xff4CAF50),
    'Tip': Color(0xffFF9800),
    'Revision': Color(0xff9C27B0),
  };

  Color _tagColor(String tag) =>
      _tagColors[tag] ?? const Color(0xff3D1975);

  @override
  Widget build(BuildContext context) {
    if (!hasMembership) {
      return _LockedState(
        onUnlock: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MemberShipScreen(model: exam.id))),
      );
    }
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('notes').child(exam.id).onValue,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff3D1975)));
        }
        List<Map<String, dynamic>> notes = [];
        if (snap.data!.snapshot.value != null) {
          final raw = snap.data!.snapshot.value as Map;
          notes = raw.values
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();
        }
        if (notes.isEmpty) {
          return const _EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'No notes yet',
            subtitle: 'Study notes for this exam will appear here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text('Study Notes',
                      style: TextStyle(
                          color: Color(0xff2D0F5E),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  _Chip('${notes.length}'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: notes.length,
                itemBuilder: (_, i) => _NoteCard(
                  note: notes[i],
                  tagColor: _tagColor(notes[i]['tag'] ?? ''),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({required this.note, required this.tagColor});
  final Map<String, dynamic> note;
  final Color tagColor;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tag = widget.note['tag'] as String? ?? 'Note';
    final title = widget.note['title'] as String? ?? '';
    final content = widget.note['content'] as String? ?? '';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: widget.tagColor, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: widget.tagColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.tagColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: widget.tagColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Color(0xff1A0540),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (_expanded && content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 8),
              Text(content,
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.65)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff3D1975).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xff3D1975),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xff3D1975).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child:
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Pro Content',
                style: TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Unlock premium study notes and preparation material with a Pro membership.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onUnlock,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xff3D1975), Color(0xff6B3FA0)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xff3D1975).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Text('Unlock Pro',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

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
              decoration: BoxDecoration(
                  color: const Color(0xff3D1975).withOpacity(0.06),
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 40,
                  color: const Color(0xff3D1975).withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Color(0xff2D0F5E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}