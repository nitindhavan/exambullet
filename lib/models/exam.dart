class ExamModel {
  String name;
  String id;
  String about;
  String banner;
  String icon;
  String goalId;
  bool enableNotes;
  bool enableQuiz;

  ExamModel.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        id = map['id'],
        about = map['about'],
        banner = map['banner'],
        icon = map['icon'],
        goalId = map['goalId'] ?? '',
        enableNotes = map['enableNotes'] ?? true,
        enableQuiz = map['enableQuiz'] ?? true;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'id': id,
      'about': about,
      'banner': banner,
      'icon': icon,
      'goalId': goalId,
      'enableNotes': enableNotes,
      'enableQuiz': enableQuiz,
    }..removeWhere((_, v) => v == null);
  }
}