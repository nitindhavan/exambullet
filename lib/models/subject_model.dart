class SubjectModel {
  final String id;
  final String examId;
  final String name;
  final int order;

  SubjectModel.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        examId = map['examId'],
        name = map['name'],
        order = (map['order'] is int)
            ? map['order'] as int
            : (map['order'] is num)
                ? (map['order'] as num).toInt()
                : 999;

  Map<String, Object?> toMap() => {
        'id': id,
        'examId': examId,
        'name': name,
        'order': order,
      };
}
