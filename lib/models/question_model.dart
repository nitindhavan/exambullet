class Question {
  final String id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int answer; // 1-based (1=A, 2=B, 3=C, 4=D)
  final int marks;
  final String imageUrl;
  final String difficulty;
  final String explanation;
  final String topic;

  Question.fromMap(Map<dynamic, dynamic> map)
      : id = map['id'] ?? '',
        questionText = map['questionText'] ?? '',
        optionA = map['optionA'] ?? '',
        optionB = map['optionB'] ?? '',
        optionC = map['optionC'] ?? '',
        optionD = map['optionD'] ?? '',
        answer = map['answer'] ?? 0,
        marks = map['marks'] ?? 1,
        imageUrl = map['imageUrl'] ?? '',
        difficulty = map['difficulty'] ?? '',
        explanation = map['explanation'] ?? '',
        topic = map['topic'] ?? '';

  String optionText(int n) {
    switch (n) {
      case 1:
        return optionA;
      case 2:
        return optionB;
      case 3:
        return optionC;
      case 4:
        return optionD;
      default:
        return '';
    }
  }
}
