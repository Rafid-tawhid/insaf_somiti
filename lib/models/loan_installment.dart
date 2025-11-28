class LoanInstallment {
  final String? id;
  final String loanId;
  final String memberId;
  final String memberName;
  final String memberNumber;
  final String memberMobile;
  final double amount;
  final int installmentNumber;
  final DateTime paymentDate;
  final double previousBalance;
  final double remainingBalance;
  final DateTime createdAt;

  LoanInstallment({
    this.id,
    required this.loanId,
    required this.memberId,
    required this.memberName,
    required this.memberNumber,
    required this.memberMobile,
    required this.amount,
    required this.installmentNumber,
    required this.paymentDate,
    required this.previousBalance,
    required this.remainingBalance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'memberId': memberId,
      'memberName': memberName,
      'memberNumber': memberNumber,
      'memberMobile': memberMobile,
      'amount': amount,
      'installmentNumber': installmentNumber,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'previousBalance': previousBalance,
      'remainingBalance': remainingBalance,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory LoanInstallment.fromMap(String id, Map<String, dynamic> map) {
    return LoanInstallment(
      id: id,
      loanId: map['loanId'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      memberNumber: map['memberNumber'] ?? '',
      memberMobile: map['memberMobile'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      installmentNumber: map['installmentNumber'] ?? 0,
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['paymentDate']),
      previousBalance: (map['previousBalance'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  LoanInstallment copyWith({
    String? id,
    String? loanId,
    String? memberId,
    String? memberName,
    String? memberNumber,
    String? memberMobile,
    double? amount,
    int? installmentNumber,
    DateTime? paymentDate,
    double? previousBalance,
    double? remainingBalance,
    DateTime? createdAt,
  }) {
    return LoanInstallment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberNumber: memberNumber ?? this.memberNumber,
      memberMobile: memberMobile ?? this.memberMobile,
      amount: amount ?? this.amount,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      previousBalance: previousBalance ?? this.previousBalance,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'LoanInstallment(id: $id, loanId: $loanId, memberId: $memberId, amount: $amount, installmentNumber: $installmentNumber, paymentDate: $paymentDate, previousBalance: $previousBalance, remainingBalance: $remainingBalance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoanInstallment &&
        other.id == id &&
        other.loanId == loanId &&
        other.memberId == memberId &&
        other.memberName == memberName &&
        other.memberNumber == memberNumber &&
        other.memberMobile == memberMobile &&
        other.amount == amount &&
        other.installmentNumber == installmentNumber &&
        other.paymentDate == paymentDate &&
        other.previousBalance == previousBalance &&
        other.remainingBalance == remainingBalance &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    loanId.hashCode ^
    memberId.hashCode ^
    memberName.hashCode ^
    memberNumber.hashCode ^
    memberMobile.hashCode ^
    amount.hashCode ^
    installmentNumber.hashCode ^
    paymentDate.hashCode ^
    previousBalance.hashCode ^
    remainingBalance.hashCode ^
    createdAt.hashCode;
  }
}