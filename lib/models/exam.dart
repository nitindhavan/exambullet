class ExamModel {
  String name;
  String id;
  String about;
  String banner;
  String icon;
  bool editable;
  bool visible;
  int price; // in paise (₹1 = 100 paise), default ₹100
  int membershipDurationDays; // 0 = lifetime / no expiry, default 365 (1 year)
  String category; // category id (see `categories` node); '' = uncategorized
  String iconKey; // named-icon key; when set, takes priority over the [icon] image

  ExamModel.fromMap(Map<dynamic, dynamic> map, [String? key])
      : name = map['name'] ?? '',
        id = map['id'] ?? key ?? '',
        about = map['about'] ?? '',
        banner = map['banner'] ?? '',
        icon = map['icon'] ?? '',
        editable = (map['editable'] ?? 0) == 1,
        visible = map['visible'] ?? false,
        price = (map['price'] as num?)?.toInt() ?? 10000,
        membershipDurationDays =
            (map['membershipDurationDays'] as num?)?.toInt() ?? 365,
        category = map['category'] ?? '',
        iconKey = map['iconKey'] ?? '';

  Map<String, Object?> toMap() => {
        'name': name,
        'id': id,
        'about': about,
        'banner': banner,
        'icon': icon,
        'editable': editable ? 1 : 0,
        'visible': visible,
        'price': price,
        'membershipDurationDays': membershipDurationDays,
        'category': category,
        'iconKey': iconKey,
      };
}
