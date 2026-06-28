class ExamModel {
  String name;
  String id;
  String about;
  String banner;
  String icon;
  bool editable;
  bool visible;
  int price; // in paise (₹1 = 100 paise), default ₹100

  ExamModel.fromMap(Map<dynamic, dynamic> map, [String? key])
      : name = map['name'] ?? '',
        id = map['id'] ?? key ?? '',
        about = map['about'] ?? '',
        banner = map['banner'] ?? '',
        icon = map['icon'] ?? '',
        editable = (map['editable'] ?? 0) == 1,
        visible = map['visible'] ?? false,
        price = (map['price'] as num?)?.toInt() ?? 10000;

  Map<String, Object?> toMap() => {
        'name': name,
        'id': id,
        'about': about,
        'banner': banner,
        'icon': icon,
        'editable': editable ? 1 : 0,
        'visible': visible,
        'price': price,
      };
}
