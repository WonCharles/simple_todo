class Todo {
  String id;
  String title;
  bool isCompleted;
  bool isPostponed;
  DateTime date;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isPostponed = false,
    required this.date,
  });

  // JSON 변환을 위한 팩토리 생성자
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      isPostponed: json['isPostponed'] ?? false,
      date: DateTime.parse(json['date']),
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isPostponed': isPostponed,
      'date': date.toIso8601String(),
    };
  }

  // 상태 변경 시 새 인스턴스 생성을 위한 복사 메서드
  Todo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isPostponed,
    DateTime? date,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isPostponed: isPostponed ?? this.isPostponed,
      date: date ?? this.date,
    );
  }
}