class Budget {
  final String? id;
  final String category;
  final double amount;
  final String month;
  final String? firestoreId;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    this.firestoreId,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    String? month,
    String? firestoreId,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'category': category,
      'amount': amount,
      'month': month,
      'firestoreId': firestoreId,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id']?.toString(),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
      firestoreId: map['firestoreId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'category': category, 'amount': amount, 'month': month};
  }

  factory Budget.fromFirestore(Map<String, dynamic> data, String id) {
    return Budget(
      id: null,
      firestoreId: id,
      category: data['category'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      month: data['month'] as String? ?? '',
    );
  }
}
