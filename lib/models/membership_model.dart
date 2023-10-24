class MembershipModel{
  String examId;
  String userId;
  String membershipDate;


  MembershipModel(this.examId, this.userId, this.membershipDate);

  MembershipModel.fromMap(Map<dynamic, dynamic> map)
      : examId = map['examId'],
        userId = map['userId'],
        membershipDate=map['membershipDate'];

  Map<String, Object?> toMap() {
    final map = {
      'examId': examId,
      'userId': userId,
      'membershipDate': membershipDate
    };
    map.removeWhere((key, value) => value==null);
    return map;
  }
}