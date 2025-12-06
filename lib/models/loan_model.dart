class Loan {
  final String? id;
  final String memberId;
  final String memberName;
  final String memberNumber;
  final String memberMobile;
  final String loanType;
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
  final DateTime updatedAt;


  Loan({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.memberNumber,
    required this.memberMobile,
    required this.loanAmount,
    required this.interestRate,
    required this.loanType,
    required this.tenureNumber,
    required this.currentTenureNumber,
    required this.loanPurpose,
    required this.loanDate,
    this.status = 'active',
    required this.totalPayable,
    required this.installmentAmount,
    required this.remainingBalance,
    this.totalPaid = 0.0,
    required this.createdAt,
    required this.updatedAt
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'memberNumber': memberNumber,
      'memberMobile': memberMobile,
      'loanType': loanType,
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
      'updatedAt': updatedAt.millisecondsSinceEpoch
    };
  }

  factory Loan.fromMap(String id, Map<String, dynamic> map) {
    return Loan(
      id: id,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      memberNumber: map['memberNumber'] ?? '',
      memberMobile: map['memberMobile'] ?? '',
      loanType: map['loanType'] ?? '',
      loanAmount: (map['loanAmount'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      tenureNumber: (map['tenureNumber'] ?? 0).toInt(),
      currentTenureNumber: (map['currentTenureNumber'] ?? 0).toInt(),
      loanPurpose: map['loanPurpose'] ?? '',
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loanDate'] ?? 0),
      status: map['status'] ?? 'active',
      totalPayable: (map['totalPayable'] ?? 0.0).toDouble(),
      installmentAmount: (map['installmentAmount'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch)
    );
  }

  Loan copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? memberNumber,
    String? memberMobile,
    String? loanType,
    double? loanAmount,
    double? interestRate,
    int? tenureNumber,
    int? currentTenureNumber,
    String? loanPurpose,
    DateTime? loanDate,
    String? status,
    double? totalPayable,
    double? installmentAmount,
    double? remainingBalance,
    double? totalPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLoanActive,
    DateTime? lastSavingsGiven, // Added
    DateTime? lastLoanGiven, // Added
  }) {
    return Loan(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberNumber: memberNumber ?? this.memberNumber,
      memberMobile: memberMobile ?? this.memberMobile,
      loanType: loanType ?? this.loanType,
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureNumber: tenureNumber ?? this.tenureNumber,
      currentTenureNumber: currentTenureNumber ?? this.currentTenureNumber,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      loanDate: loanDate ?? this.loanDate,
      status: status ?? this.status,
      totalPayable: totalPayable ?? this.totalPayable,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt
    );
  }
}