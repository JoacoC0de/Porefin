class Payable {
  final String id;
  final String creditorName;
  final double initialAmount;
  final double currentBalance;
  final DateTime dueDate;
  final String? description;
  final bool isPaidOff;

  Payable({
    required this.id,
    required this.creditorName,
    required this.initialAmount,
    required this.currentBalance,
    required this.dueDate,
    this.description,
    this.isPaidOff = false,
  });

  Payable copyWith({
    String? id,
    String? creditorName,
    double? initialAmount,
    double? currentBalance,
    DateTime? dueDate,
    String? description,
    bool? isPaidOff,
  }) {
    return Payable(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      initialAmount: initialAmount ?? this.initialAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      isPaidOff: isPaidOff ?? this.isPaidOff,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditor_name': creditorName,
      'initial_amount': initialAmount,
      'current_balance': currentBalance,
      'due_date': dueDate.millisecondsSinceEpoch,
      'description': description,
      'is_paid_off': isPaidOff ? 1 : 0,
    };
  }

  factory Payable.fromMap(Map<String, dynamic> map) {
    return Payable(
      id: map['id'] as String,
      creditorName: map['creditor_name'] as String,
      initialAmount: (map['initial_amount'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      description: map['description'] as String?,
      isPaidOff: (map['is_paid_off'] as int? ?? 0) == 1,
    );
  }
}
