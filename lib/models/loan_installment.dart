// models/installment_transaction_model.dart
class InstallmentTransaction {
  final String? id;
  final String loanId;
  final String memberId;
  final double amount;
  final int numberOfInstallments;
  final DateTime paymentDate;
  final String paymentMethod; // 'cash', 'bank', 'mobile_banking'
  final String? referenceNumber;
  final String note;
  final DateTime createdAt;

  InstallmentTransaction({
    this.id,
    required this.loanId,
    required this.memberId,
    required this.amount,
    required this.numberOfInstallments,
    required this.paymentDate,
    this.paymentMethod = 'cash',
    this.referenceNumber,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'memberId': memberId,
      'amount': amount,
      'numberOfInstallments': numberOfInstallments,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory InstallmentTransaction.fromMap(String id, Map<String, dynamic> map) {
    return InstallmentTransaction(
      id: id,
      loanId: map['loanId'] ?? '',
      memberId: map['memberId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      numberOfInstallments: map['numberOfInstallments'] ?? 1,
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['paymentDate']),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      referenceNumber: map['referenceNumber'],
      note: map['note'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}