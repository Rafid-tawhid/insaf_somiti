// models/cashbox_summary_model.dart
class CashboxSummary {
  final double totalSavings;
  final double totalWithdrawals;
  final double totalLoanGiven;
  final double totalLoanCollected;
  final double totalLoanPending;
  final double currentBalance;
  final int totalMembers;
  final int activeLoans;
  final int completedLoans;
  final DateTime lastUpdated;

  CashboxSummary({
    required this.totalSavings,
    required this.totalWithdrawals,
    required this.totalLoanGiven,
    required this.totalLoanCollected,
    required this.totalLoanPending,
    required this.currentBalance,
    required this.totalMembers,
    required this.activeLoans,
    required this.completedLoans,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalSavings': totalSavings,
      'totalWithdrawals': totalWithdrawals,
      'totalLoanGiven': totalLoanGiven,
      'totalLoanCollected': totalLoanCollected,
      'totalLoanPending': totalLoanPending,
      'currentBalance': currentBalance,
      'totalMembers': totalMembers,
      'activeLoans': activeLoans,
      'completedLoans': completedLoans,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory CashboxSummary.fromMap(Map<String, dynamic> map) {
    return CashboxSummary(
      totalSavings: (map['totalSavings'] ?? 0.0).toDouble(),
      totalWithdrawals: (map['totalWithdrawals'] ?? 0.0).toDouble(),
      totalLoanGiven: (map['totalLoanGiven'] ?? 0.0).toDouble(),
      totalLoanCollected: (map['totalLoanCollected'] ?? 0.0).toDouble(),
      totalLoanPending: (map['totalLoanPending'] ?? 0.0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      totalMembers: map['totalMembers'] ?? 0,
      activeLoans: map['activeLoans'] ?? 0,
      completedLoans: map['completedLoans'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
    );
  }
}