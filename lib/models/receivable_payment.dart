class ReceivablePayment {
  final String id;
  final String receivableId;
  final double amount;
  final DateTime paymentDate;
  final String? note;

  ReceivablePayment({
    required this.id,
    required this.receivableId,
    required this.amount,
    required this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receivable_id': receivableId,
      'amount': amount,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory ReceivablePayment.fromMap(Map<String, dynamic> map) {
    return ReceivablePayment(
      id: map['id'] as String,
      receivableId: map['receivable_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date'] as int),
      note: map['note'] as String?,
    );
  }
}
