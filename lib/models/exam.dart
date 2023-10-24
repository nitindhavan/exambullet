class ExamModel{
  String name;
  String id;
  String about;
  String banner;
  String icon;


  ExamModel.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        id = map['id'],
        about = map['about'],
        banner=map['banner'],
        icon=map['icon'];

  Map<String, Object?> toMap() {
    final map = {
      'name': name,
      'id': id,
      'about': about,
      'banner': banner,
      'icon': icon
    };
    map.removeWhere((key, value) => value==null);
    return map;
  }

}