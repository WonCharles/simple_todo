class MonthlyGoal {
  String id;
  String content;
  int year;
  int month;
  bool isCompleted;

  MonthlyGoal({
    required this.id,
    required this.content,
    required this.year,
    required this.month,
    this.isCompleted = false,
  });

  // JSON 변환을 위한 팩토리 생성자
  factory MonthlyGoal.fromJson(Map<String, dynamic> json) {
    return MonthlyGoal(
      id: json['id'],
      content: json['content'],
      year: json['year'],
      month: json['month'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'year': year,
      'month': month,
      'isCompleted': isCompleted,
    };
  }

  // 상태 변경 시 새 인스턴스 생성을 위한 복사 메서드
  MonthlyGoal copyWith({
    String? id,
    String? content,
    int? year,
    int? month,
    bool? isCompleted,
  }) {
    return MonthlyGoal(
      id: id ?? this.id,
      content: content ?? this.content,
      year: year ?? this.year,
      month: month ?? this.month,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}