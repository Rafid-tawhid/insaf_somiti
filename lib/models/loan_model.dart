class Loan {
  final String? id;
  final String memberId;
  final String memberName;
  final String memberNumber;
  final String memberMobile;
  final double loanAmount;
  final double interestRate;
  final int tenureNumber;
  final int currentTenureNumber;
  final String loanPurpose;
  final DateTime loanDate;
  final String status; // 'active', 'completed'
  final double totalPayable;
  final double installmentAmount;
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
    required this.tenureNumber,
    required this.loanPurpose,
    required this.currentTenureNumber,
    required this.loanDate,
    this.status = 'active',
    required this.totalPayable,
    required this.installmentAmount,
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
      'tenureNumber': tenureNumber,
      'currentTenureNumber': currentTenureNumber,
      'loanPurpose': loanPurpose,
      'loanDate': loanDate.millisecondsSinceEpoch,
      'status': status,
      'totalPayable': totalPayable,
      'installmentAmount': installmentAmount,
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
      currentTenureNumber: map['currentTenureNumber'] ?? '',
      loanAmount: (map['loanAmount'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      tenureNumber: map['tenureNumber'] ?? 0,
      loanPurpose: map['loanPurpose'] ?? '',
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loanDate']),
      status: map['status'] ?? 'active',
      totalPayable: (map['totalPayable'] ?? 0.0).toDouble(),
      installmentAmount: (map['installmentAmount'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}