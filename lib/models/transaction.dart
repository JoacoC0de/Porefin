class Transaction {
  final String id;
  final double amount;
  final String type;
  final String category;
  final String icon;
  final String? description;
  final DateTime date;
  final bool isRecurring;
  final String? accountId;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.icon,
    this.description,
    required this.date,
    this.isRecurring = false,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'icon': icon,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'is_recurring': isRecurring ? 1 : 0,
      'account_id': accountId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      icon: map['icon'] as String,
      description: map['description'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      accountId: map['account_id'] as String?,
    );
  }
}