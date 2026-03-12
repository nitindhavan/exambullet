class SubjectModel {
  final String id;
  final String examId;
  final String name;

  SubjectModel.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        examId = map['examId'],
        name = map['name'];

  Map<String, Object?> toMap() => {
        'id': id,
        'examId': examId,
        'name': name,
      };
}