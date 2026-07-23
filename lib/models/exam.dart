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

  // Schedule dates (epoch milliseconds, UTC). Null = not announced/unknown.
  int? notificationDate; // official notification / announcement release
  int? formStartDate; // application window opens
  int? formEndDate; // application deadline
  int? examDate; // exam day (or first day of a multi-day exam)
  int? resultDate; // result declaration

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
        iconKey = map['iconKey'] ?? '',
        notificationDate = (map['notificationDate'] as num?)?.toInt(),
        formStartDate = (map['formStartDate'] as num?)?.toInt(),
        formEndDate = (map['formEndDate'] as num?)?.toInt(),
        examDate = (map['examDate'] as num?)?.toInt(),
        resultDate = (map['resultDate'] as num?)?.toInt();

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
        'notificationDate': notificationDate,
        'formStartDate': formStartDate,
        'formEndDate': formEndDate,
        'examDate': examDate,
        'resultDate': resultDate,
      };

  /// All schedule dates as (label, millis) pairs. Callers decide how to
  /// filter/sort per section. Skips unset dates.
  List<MapEntry<String, int>> get scheduleEvents => [
        if (notificationDate != null)
          MapEntry('Notification', notificationDate!),
        if (formStartDate != null) MapEntry('Forms Open', formStartDate!),
        if (formEndDate != null) MapEntry('Forms Close', formEndDate!),
        if (examDate != null) MapEntry('Exam Date', examDate!),
        if (resultDate != null) MapEntry('Result', resultDate!),
      ];
}
