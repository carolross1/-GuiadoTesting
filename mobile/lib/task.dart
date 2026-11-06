/// Converts a JSON object into a task value.
class Task {
  /// Creates a task.
  const Task({
    required this.id,
    required this.title,
    this.completed = false,
  });

  /// Unique server identifier.
  final String id;

  /// User-visible task title.
  final String title;

  /// Whether the task is completed.
  final bool completed;

  /// Parses a task from JSON.
  ///
  /// Throws [FormatException] when required fields are missing or invalid.
  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || title is! String || title.trim().isEmpty) {
      throw const FormatException('Invalid task data.');
    }
    return Task(
      id: id,
      title: title,
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }

  Task copyWith({String? id, String? title, bool? completed}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
