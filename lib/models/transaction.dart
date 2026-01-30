class Transaction {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String? description;
  final String? accountId;
  final String? firestoreId;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.description,
    this.accountId,
    this.firestoreId,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? type,
    String? description,
    String? accountId,
    String? firestoreId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'description': description,
      'accountId': accountId,
      'firestoreId': firestoreId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: map['type'] as String,
      description: map['description'] as String?,
      accountId: map['accountId'] as String?,
      firestoreId: map['firestoreId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'type': type,
      'description': description,
      'accountId': accountId,
    };
  }

  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: null, // Don't use Firestore ID as local primary key
      firestoreId: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int? ?? 0),
      type: data['type'] as String? ?? 'expense',
      description: data['description'] as String?,
      accountId: data['accountId'] as String?,
    );
  }
}
