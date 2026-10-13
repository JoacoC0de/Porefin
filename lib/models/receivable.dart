class Receivable {
  final String id;
  final String personName;
  final double initialAmount;
  final double currentBalance;
  final DateTime loanDate;
  final String? description;
  final bool isPaidOff;

  Receivable({
    required this.id,
    required this.personName,
    required this.initialAmount,
    required this.currentBalance,
    required this.loanDate,
    this.description,
    this.isPaidOff = false,
  });

  Receivable copyWith({
    String? id,
    String? personName,
    double? initialAmount,
    double? currentBalance,
    DateTime? loanDate,
    String? description,
    bool? isPaidOff,
  }) {
    return Receivable(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      initialAmount: initialAmount ?? this.initialAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      loanDate: loanDate ?? this.loanDate,
      description: description ?? this.description,
      isPaidOff: isPaidOff ?? this.isPaidOff,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'initial_amount': initialAmount,
      'current_balance': currentBalance,
      'loan_date': loanDate.millisecondsSinceEpoch,
      'description': description,
      'is_paid_off': isPaidOff ? 1 : 0,
    };
  }

  factory Receivable.fromMap(Map<String, dynamic> map) {
    return Receivable(
      id: map['id'] as String,
      personName: map['person_name'] as String,
      initialAmount: (map['initial_amount'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loan_date'] as int),
      description: map['description'] as String?,
      isPaidOff: (map['is_paid_off'] as int? ?? 0) == 1,
    );
  }
}
