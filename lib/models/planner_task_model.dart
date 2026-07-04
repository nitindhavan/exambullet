class PlannerTask {
  final String id;
  final String text;
  final bool done;
  final int createdAt; // millisecondsSinceEpoch, used for stable ordering

  PlannerTask({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  PlannerTask.fromMap(Map<dynamic, dynamic> map, String key)
      : id = map['id'] ?? key,
        text = map['text'] ?? '',
        done = map['done'] ?? false,
        createdAt = (map['createdAt'] as num?)?.toInt() ?? 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'text': text,
        'done': done,
        'createdAt': createdAt,
      };
}
