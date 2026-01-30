class Goal {
  final String? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon;
  final String? firestoreId;

  Goal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.icon = '🎯',
    this.firestoreId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'icon': icon,
      'firestoreId': firestoreId,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id']?.toString(),
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: DateTime.parse(map['deadline'] as String),
      icon: (map['icon'] as String?) ?? '🎯',
      firestoreId: map['firestoreId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.millisecondsSinceEpoch,
      'icon': icon,
    };
  }

  factory Goal.fromFirestore(Map<String, dynamic> data, String id) {
    return Goal(
      id: null,
      firestoreId: id,
      title: data['title'] as String? ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: DateTime.fromMillisecondsSinceEpoch(
        data['deadline'] as int? ?? 0,
      ),
      icon: data['icon'] as String? ?? '🎯',
    );
  }

  double get progress => currentAmount / targetAmount;

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? firestoreId,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
}
