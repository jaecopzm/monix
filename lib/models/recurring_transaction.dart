class RecurringTransaction {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastProcessed;
  final bool isActive;
  final String? description;

  RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastProcessed,
    this.isActive = true,
    this.description,
  });

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? type,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastProcessed,
    bool? isActive,
    String? description,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastProcessed: lastProcessed ?? this.lastProcessed,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'frequency': frequency,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'lastProcessed': lastProcessed?.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'description': description,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id']?.toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: map['type'] as String,
      frequency: map['frequency'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      lastProcessed: map['lastProcessed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastProcessed'] as int)
          : null,
      isActive: map['isActive'] == 1,
      description: map['description'] as String?,
    );
  }

  DateTime getNextDueDate() {
    final base = lastProcessed ?? startDate;
    switch (frequency) {
      case 'daily':
        return DateTime(base.year, base.month, base.day + 1);
      case 'weekly':
        return DateTime(base.year, base.month, base.day + 7);
      case 'monthly':
        return DateTime(base.year, base.month + 1, base.day);
      case 'yearly':
        return DateTime(base.year + 1, base.month, base.day);
      default:
        return base;
    }
  }

  bool isDue() {
    if (!isActive) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    return DateTime.now().isAfter(getNextDueDate());
  }
}
