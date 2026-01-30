class Category {
  final String? id;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' or 'expense'
  final String? firestoreId;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.firestoreId,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    String? firestoreId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'firestoreId': firestoreId,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toString(),
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: map['type'] as String,
      firestoreId: map['firestoreId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'icon': icon, 'color': color, 'type': type};
  }

  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: null,
      firestoreId: id,
      name: data['name'] as String? ?? '',
      icon: data['icon'] as String? ?? '',
      color: data['color'] as String? ?? '',
      type: data['type'] as String? ?? 'expense',
    );
  }
}
