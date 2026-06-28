class TestModel {
  String name;
  String id;
  int time;
  int negativeMarks;

  TestModel.fromMap(Map<dynamic, dynamic> map)
      : name          = map['name'],
        id            = map['id'],
        time          = map['time'] ?? 0,
        negativeMarks = map['negative_marks'] != null
            ? (map['negative_marks'] as num).toInt()
            : 0;

  Map<String, Object?> toMap() => {
        'name':           name,
        'id':             id,
        'time':           time,
        'negative_marks': negativeMarks,
      };
}
