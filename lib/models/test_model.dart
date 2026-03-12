class TestModel {
  String name;
  String id;
  int time;

  TestModel.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        id = map['id'],
        time = map['time'] ?? 0;

  Map<String, Object?> toMap() => {
        'name': name,
        'id': id,
        'time': time,
      };
}