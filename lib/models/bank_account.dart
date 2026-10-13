class BankAccount {
  final String id;
  final String name;
  final double initialBalance;
  final String icon;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    required this.name,
    required this.initialBalance,
    this.icon = '🏦',
    required this.createdAt,
  });

  BankAccount copyWith({
    String? id,
    String? name,
    double? initialBalance,
    String? icon,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      initialBalance: (map['initial_balance'] as num? ?? 0).toDouble(),
      icon: map['icon'] as String? ?? '🏦',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
