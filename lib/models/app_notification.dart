class AppNotification {
  final String? id;
  final String title;
  final String message;
  final String type; // recurring_due, budget_alert, goal_achieved, insight
  final DateTime createdAt;
  final bool isRead;
  final String? actionData; // JSON data for action (e.g., transaction ID)

  AppNotification({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'actionData': actionData,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString(),
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isRead: map['isRead'] == 1,
      actionData: map['actionData'] as String?,
    );
  }
}
