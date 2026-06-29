class UserModel{
  static final UserModel guest = UserModel('Guest', '', '__guest__', []);

  String name;
  String phone;
  String uid;
  List<dynamic>? memberships;
  String? createdAt;

  bool get isGuest => uid == '__guest__';

  UserModel(this.name, this.phone, this.uid, this.memberships, [this.createdAt]);

  UserModel.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        phone = map['phone'],
        uid = map['uid'],
        memberships = map['memberships'],
        createdAt = map['createdAt'];

  Map<String, Object?> toMap() {
    final map = {
      'name': name,
      'phone': phone,
      'uid': uid,
      'memberships': memberships,
      'createdAt': createdAt,
    };
    map.removeWhere((key, value) => value==null);
    return map;
  }
}
