class Account {
  final String? id;
  final String name;
  final String type; // 'cash', 'bank', 'credit_card', 'savings', 'investment'
  final double balance;
  final String icon;
  final String color;
  final bool isDefault;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.icon = '💰',
    this.color = '6C63FF',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      'color': color,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id']?.toString(),
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      icon: (map['icon'] as String?) ?? '💰',
      color: (map['color'] as String?) ?? '6C63FF',
      isDefault: map['isDefault'] == 1,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
