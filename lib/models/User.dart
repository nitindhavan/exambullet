class UserModel{
  String name;
  String phone;
  String uid;
  List<String>? memberships;

  UserModel(this.name, this.phone, this.uid, this.memberships);

  UserModel.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        phone = map['phone'],
        uid = map['uid'],
  memberships=map['memberships'];

  Map<String, Object?> toMap() {
    final map = {
      'name': name,
      'phone': phone,
      'uid': uid,
      'memberships': memberships
    };
    map.removeWhere((key, value) => value==null);
    return map;
  }

}