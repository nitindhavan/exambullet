/// Admin-authored study notes ("Theory") for a single topic, stored at
/// `topicNotes/{topicId}`.
///
/// IMPORTANT: this deliberately lives at its own root rather than under
/// `topicContent/{topicId}` — the YouTube/article scrapers call `.set()` on the
/// whole `topicContent` node, which would wipe any sibling keys on every
/// re-scrape.
///
/// [content] is Markdown. Diagrams are embedded as raw `<svg>…</svg>` blocks
/// inside the markdown (rendered via flutter_svg), so a note is a single
/// self-contained text field — no image hosting required.
class TopicNotes {
  final String topicId;
  final String content; // markdown (may contain inline <svg> blocks)
  final int updatedAt; // epoch ms

  const TopicNotes({
    required this.topicId,
    required this.content,
    required this.updatedAt,
  });

  bool get isEmpty => content.trim().isEmpty;

  Map<String, Object?> toMap() => {
        'topicId': topicId,
        'content': content,
        'updatedAt': updatedAt,
      };

  factory TopicNotes.fromMap(Map<dynamic, dynamic> m, String topicId) =>
      TopicNotes(
        topicId: (m['topicId'] ?? topicId).toString(),
        content: (m['content'] ?? '').toString(),
        updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
      );
}
