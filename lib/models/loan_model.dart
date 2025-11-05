class Loan {
  final String? id;
  final String memberId;
  final String memberName;
  final String memberNumber;
  final String memberMobile;
  final double loanAmount;
  final double interestRate;
  final int tenureMonths;
  final String loanPurpose;
  final DateTime loanDate;
  final String status; // 'active', 'completed'
  final double totalPayable;
  final double monthlyInstallment;
  final double remainingBalance;
  final double totalPaid;
  final DateTime createdAt;

  Loan({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.memberNumber,
    required this.memberMobile,
    required this.loanAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.loanPurpose,
    required this.loanDate,
    this.status = 'active',
    required this.totalPayable,
    required this.monthlyInstallment,
    required this.remainingBalance,
    this.totalPaid = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'memberNumber': memberNumber,
      'memberMobile': memberMobile,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'loanPurpose': loanPurpose,
      'loanDate': loanDate.millisecondsSinceEpoch,
      'status': status,
      'totalPayable': totalPayable,
      'monthlyInstallment': monthlyInstallment,
      'remainingBalance': remainingBalance,
      'totalPaid': totalPaid,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Loan.fromMap(String id, Map<String, dynamic> map) {
    return Loan(
      id: id,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      memberNumber: map['memberNumber'] ?? '',
      memberMobile: map['memberMobile'] ?? '',
      loanAmount: (map['loanAmount'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      tenureMonths: map['tenureMonths'] ?? 0,
      loanPurpose: map['loanPurpose'] ?? '',
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loanDate']),
      status: map['status'] ?? 'active',
      totalPayable: (map['totalPayable'] ?? 0.0).toDouble(),
      monthlyInstallment: (map['monthlyInstallment'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}