class PayablePayment {
  final String id;
  final String payableId;
  final double amount;
  final DateTime paymentDate;
  final String? note;

  PayablePayment({
    required this.id,
    required this.payableId,
    required this.amount,
    required this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payable_id': payableId,
      'amount': amount,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory PayablePayment.fromMap(Map<String, dynamic> map) {
    return PayablePayment(
      id: map['id'] as String,
      payableId: map['payable_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date'] as int),
      note: map['note'] as String?,
    );
  }
}
