class Question{
  String id;
  String testId;
  String examId;
  String imageUrl;
  int answer;
  int marks;

  Question(this.id, this.testId, this.examId, this.imageUrl, this.answer,
      this.marks);

  Question.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'],
        testId=map['testId'],
        examId=map['examId'],
        imageUrl=map['imageUrl'],
        answer=map['answer'],
        marks=map['marks'];

  Map<String, Object?> toMap() {
    final map = {
      'id': id,
      'testId': testId,
      'examId': examId,
      'imageUrl': imageUrl,
      'answer': answer,
      'marks': marks
    };
    map.removeWhere((key, value) => value==null);
    return map;
  }
}