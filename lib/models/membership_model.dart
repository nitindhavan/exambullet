class MembershipModel {
  String examId;
  String userId;
  String membershipDate;
  bool isActive;
  String? paymentId;

  MembershipModel(this.examId, this.userId, this.membershipDate,
      {this.isActive = true, this.paymentId});

  MembershipModel.fromMap(Map<dynamic, dynamic> map)
      : examId = map['examId'],
        userId = map['userId'],
        membershipDate = map['membershipDate'],
        isActive = map['isActive'] ?? true,
        paymentId = map['paymentId'] as String?;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'examId': examId,
      'userId': userId,
      'membershipDate': membershipDate,
      'isActive': isActive,
      'paymentId': paymentId,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
