class TopicModel {
  final String id;
  final String subjectId;
  final String examId;
  final String name;

  TopicModel.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        subjectId = map['subjectId'],
        examId = map['examId'],
        name = map['name'];

  Map<String, Object?> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'examId': examId,
        'name': name,
      };
}