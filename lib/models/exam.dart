class ExamModel {
  String name;
  String id;
  String about;
  String banner;
  String icon;
  bool editable;
  bool visible;

  ExamModel.fromMap(Map<dynamic, dynamic> map, [String? key])
      : name = map['name'] ?? '',
        id = map['id'] ?? key ?? '',
        about = map['about'] ?? '',
        banner = map['banner'] ?? '',
        icon = map['icon'] ?? '',
        editable = (map['editable'] ?? 0) == 1,
        visible = map['visible'] ?? false;

  Map<String, Object?> toMap() => {
        'name': name,
        'id': id,
        'about': about,
        'banner': banner,
        'icon': icon,
        'editable': editable ? 1 : 0,
        'visible': visible,
      };
}
