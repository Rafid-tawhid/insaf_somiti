class TransactionModel {
  final String? id;
  final String memberId;
  final String memberName;
  final String memberNumber;
  final String memberMobile;
  final String transactionType; // 'savings', 'withdrawal', etc.
  final double amount;
  final double balanceAfter;
  final String agentId;
  final String agentName;
  final String? notes;
  final DateTime transactionDate;

  TransactionModel({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.memberNumber,
    required this.memberMobile,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.agentId,
    required this.agentName,
    this.notes,
    required this.transactionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'memberNumber': memberNumber,
      'memberMobile': memberMobile,
      'transactionType': transactionType,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'agentId': agentId,
      'agentName': agentName,
      'notes': notes,
      'transactionDate': transactionDate.millisecondsSinceEpoch,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      memberNumber: map['memberNumber'] ?? '',
      memberMobile: map['memberMobile'] ?? '',
      transactionType: map['transactionType'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0.0).toDouble(),
      agentId: map['agentId'] ?? '',
      agentName: map['agentName'] ?? '',
      notes: map['notes'],
      transactionDate: DateTime.fromMillisecondsSinceEpoch(map['transactionDate']),
    );
  }

  @override
  String toString() {
    return 'TransactionModel{id: $id, memberId: $memberId, memberName: $memberName, memberNumber: $memberNumber, memberMobile: $memberMobile, transactionType: $transactionType, amount: $amount, balanceAfter: $balanceAfter, agentId: $agentId, agentName: $agentName, notes: $notes, transactionDate: $transactionDate}';
  }


}