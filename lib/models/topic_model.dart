class TopicModel {
  final String id;
  final String subjectId;
  final String examId;
  final String name;
  final int order;
  final bool hasContent;

  TopicModel.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        subjectId = map['subjectId'],
        examId = map['examId'],
        name = map['name'],
        order = (map['order'] is int)
            ? map['order'] as int
            : (map['order'] is num)
                ? (map['order'] as num).toInt()
                : 999,
        hasContent = map['hasContent'] == true;

  Map<String, Object?> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'examId': examId,
        'name': name,
        'order': order,
        'hasContent': hasContent,
      };
}
