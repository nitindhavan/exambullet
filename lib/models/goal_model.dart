class GoalModel {
  final String id;
  final String name;
  final String icon;

  GoalModel.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        name = map['name'],
        icon = map['icon'] ?? '';

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
      };
}
