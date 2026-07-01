class MembershipModel {
  String examId;
  String userId;
  String membershipDate;
  bool isActive;
  String? paymentId;
  String? expiryDate; // ISO-8601; null = lifetime / no expiry

  MembershipModel(this.examId, this.userId, this.membershipDate,
      {this.isActive = true, this.paymentId, this.expiryDate});

  MembershipModel.fromMap(Map<dynamic, dynamic> map)
      : examId = map['examId'],
        userId = map['userId'],
        membershipDate = map['membershipDate'],
        isActive = map['isActive'] ?? true,
        paymentId = map['paymentId'] as String?,
        expiryDate = map['expiryDate'] as String?;

  /// True when the membership has an [expiryDate] that is in the past.
  bool get isExpired {
    if (expiryDate == null) return false; // lifetime
    final exp = DateTime.tryParse(expiryDate!);
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'examId': examId,
      'userId': userId,
      'membershipDate': membershipDate,
      'isActive': isActive,
      'paymentId': paymentId,
      'expiryDate': expiryDate,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
