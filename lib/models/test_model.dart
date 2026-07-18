class TestModel {
  String name;
  String id;
  int time;
  double negativeMarks; // may be fractional, e.g. 0.33

  TestModel.fromMap(Map<dynamic, dynamic> map)
      : name          = map['name'],
        id            = map['id'],
        time          = map['time'] ?? 0,
        negativeMarks = map['negative_marks'] != null
            ? (map['negative_marks'] as num).toDouble()
            : 0;

  Map<String, Object?> toMap() => {
        'name':           name,
        'id':             id,
        'time':           time,
        'negative_marks': negativeMarks,
      };
}
